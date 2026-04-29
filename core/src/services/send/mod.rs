pub mod utils;

use std::{
    collections::HashMap,
    net::SocketAddr,
    path::PathBuf,
    str::FromStr,
    sync::{Arc, LazyLock},
    time::Duration,
};

use crate::{
    consts::{IRPC_ALPN, TRANSFER_ALPN},
    frb_generated::StreamSink,
    progresses::{MultiProgress, Phase, ProgressObserver, ProgressState},
    protos::SendServiceProtocol,
    services::send::utils::import,
    types::BlobInfo,
    utils::{decompress_ticket, get_or_create_secret},
};
use crate::{protos::SendServiceMessage, types::SendResult};

use anyhow::{anyhow, Result};
use iroh::{endpoint::presets::Minimal, protocol::Router, Endpoint, RelayMap, RelayMode, RelayUrl};
use iroh_blobs::{
    provider::events::{ConnectMode, EventMask, EventSender, ProviderMessage, RequestMode, RequestUpdate},
    store::fs::FsStore,
    ticket::BlobTicket,
    BlobFormat, BlobsProtocol,
};
use irpc::{Client, WithChannels};
use irpc_iroh::IrohProtocol;
use parking_lot::{Mutex, RwLock};
use tempfile::{Builder, TempDir};
use tokio::{
    sync::mpsc::{self, Receiver, UnboundedReceiver, UnboundedSender},
    task::JoinSet,
    time,
};
use tokio_util::{sync::CancellationToken, task::AbortOnDropHandle};
use tracing::error;
use uuid::Uuid;

static TOKENS: LazyLock<Mutex<HashMap<String, CancellationToken>>> = LazyLock::new(|| Mutex::new(HashMap::with_capacity(2)));

#[derive(Debug)]
pub(super) struct SendArgs {
    paths: Vec<PathBuf>,
    magic_addr: Option<SocketAddr>,
    relay: RelayMode,
}

impl SendArgs {
    pub fn new(paths: Vec<String>, magic_addr: Option<String>, relay: Option<String>) -> Result<Self> {
        let paths = paths.into_iter().filter_map(|p| PathBuf::from(p).canonicalize().ok()).collect::<Vec<PathBuf>>();
        if paths.is_empty() {
            return Err(anyhow!("no valid paths provided"));
        }
        let magic_addr = magic_addr.map(|u| SocketAddr::from_str(&u)).transpose()?;
        let relay = relay
            .map(|u| RelayUrl::from_str(&u).map(|url| RelayMode::Custom(RelayMap::from_iter(vec![url]))))
            .transpose()?
            .unwrap_or(RelayMode::Disabled);
        Ok(Self { paths, magic_addr, relay })
    }
}

impl ProgressObserver for StreamSink<Vec<ProgressState>> {
    fn on_update(&self, state: Vec<ProgressState>) {
        let _ = self.add(state);
    }
}

struct TransferState {
    connection_id: u64,
    index: u64,
    is_completed: bool,
    is_failed: bool,
}

impl TransferState {
    fn new(connection_id: u64, index: u64, is_completed: bool, is_failed: bool) -> Self {
        Self {
            connection_id,
            index,
            is_completed,
            is_failed,
        }
    }
}

fn tempdir_in(dir: PathBuf) -> Result<TempDir> {
    let dir = Builder::new().prefix(".droplus-send-").rand_bytes(6).tempdir_in(dir)?;
    Ok(dir)
}

async fn actor(mut rx: tokio::sync::mpsc::Receiver<SendServiceMessage>, files: Vec<BlobInfo>) {
    while let Some(msg) = rx.recv().await {
        match msg {
            SendServiceMessage::ListFiles(msg) => {
                let WithChannels { tx, .. } = msg;
                tx.send(files.clone()).await.ok();
            }
        }
    }
}

fn listen_rpc(files: Vec<BlobInfo>) -> IrohProtocol<SendServiceProtocol> {
    let (tx, rx) = mpsc::channel(16);
    tokio::task::spawn(actor(rx, files));
    let client = Client::<SendServiceProtocol>::local(tx);
    IrohProtocol::with_sender(client.as_local().unwrap())
}

async fn request_progress(
    request_id: u64,
    connection_id: u64,
    hashes: Arc<RwLock<HashMap<u64, HashMap<u64, u64>>>>,
    utx: UnboundedSender<TransferState>,
    mut rx: irpc::channel::mpsc::Receiver<RequestUpdate>,
) {
    if request_id != 0 {
        let (mut index, mut size) = (0, 0);
        while let Ok(Some(r)) = rx.recv().await {
            match r {
                RequestUpdate::Started(r) => {
                    (index, size) = (r.index, r.size);
                }
                RequestUpdate::Progress(r) => {
                    if r.end_offset.eq(&size) {
                        utx.send(TransferState::new(connection_id, index, false, false)).unwrap();
                    }
                }
                RequestUpdate::Completed(_) => {
                    utx.send(TransferState::new(connection_id, 0, true, false)).unwrap();
                }
                RequestUpdate::Aborted(_) => {
                    utx.send(TransferState::new(connection_id, 0, false, true)).unwrap();
                }
            }
        }
    } else {
        let map = Arc::new(RwLock::new(HashMap::new()));
        while let Ok(Some(r)) = rx.recv().await {
            match r {
                RequestUpdate::Started(r) => {
                    map.write().insert(r.index, r.size);
                }
                RequestUpdate::Completed(_) => {
                    hashes.write().insert(connection_id, map.read().clone());
                }
                _ => {}
            }
        }
    }
}

async fn update_progress(
    mp: Arc<MultiProgress>,
    hashes: Arc<RwLock<HashMap<u64, HashMap<u64, u64>>>>,
    connections: Arc<RwLock<HashMap<u64, Uuid>>>,
    mut urx: UnboundedReceiver<TransferState>,
) {
    let mut map = HashMap::new();
    while let Some(s) = urx.recv().await {
        let value = connections.read().get(&s.connection_id).cloned();
        match value {
            Some(id) => {
                let total = hashes
                    .read()
                    .get(&s.connection_id)
                    .unwrap()
                    .iter()
                    .filter_map(|(k, v)| {
                        if k <= &s.index {
                            return Some(v);
                        }
                        None
                    })
                    .sum::<u64>();
                if !s.is_completed && !s.is_failed {
                    map.insert(s.connection_id, s.index);
                    mp.set_position(&id, total);
                } else {
                    mp.change_phase(
                        &id,
                        Phase::Uploading {
                            connection_id: s.connection_id,
                            is_completed: s.is_completed,
                            is_failed: s.is_failed,
                        },
                        Some(total),
                    );
                    mp.remove(&id);
                    hashes.write().remove(&s.connection_id);
                }
            }
            None => {
                error!("got request for unknown connection {}", s.connection_id);
            }
        }
    }
}

async fn provide_progress(mp: Arc<MultiProgress>, mut recv: Receiver<ProviderMessage>) -> Result<()> {
    let connections = Arc::new(RwLock::new(HashMap::new()));
    let hashes = Arc::new(RwLock::new(HashMap::new()));
    let (utx, urx) = mpsc::unbounded_channel();
    let handle = AbortOnDropHandle::new(tokio::task::spawn(update_progress(mp.clone(), hashes.clone(), connections.clone(), urx)));
    let mut tasks = JoinSet::new();
    loop {
        match recv.recv().await {
            Some(item) => {
                match item {
                    ProviderMessage::ClientConnectedNotify(msg) => {
                        let connection_id = msg.connection_id;
                        let id = mp.add(Phase::Uploading {
                            connection_id,
                            is_failed: false,
                            is_completed: false,
                        });
                        connections.write().insert(msg.connection_id, id);
                    }
                    ProviderMessage::GetRequestReceivedNotify(msg) => {
                        tasks.spawn(request_progress(msg.request_id, msg.connection_id, hashes.clone(), utx.clone(), msg.rx));
                    }
                    _ => {}
                };
            }
            None => break,
        }
    }
    while let Some(task) = tasks.join_next().await {
        task?
    }
    handle.await?;
    Ok(())
}

pub(super) async fn start(args: SendArgs, stream: StreamSink<Vec<ProgressState>>, result: &StreamSink<SendResult>) -> Result<()> {
    let SendArgs { paths, magic_addr, relay } = args;
    let secret_key = get_or_create_secret()?;
    let mut builder = Endpoint::builder(Minimal)
        .alpns(vec![TRANSFER_ALPN.to_vec()])
        .secret_key(secret_key)
        .relay_mode(relay.clone());
    if let Some(addr) = magic_addr {
        builder = builder.bind_addr(addr)?;
    }
    let blobs_dir = tempdir_in(std::env::temp_dir())?;
    let mp = Arc::new(MultiProgress::new(Arc::new(stream)));
    let endpoint = builder.bind().await?;
    let store = FsStore::load(blobs_dir.path()).await?;
    let (tx, rx) = mpsc::channel(128);
    let progress = AbortOnDropHandle::new(tokio::task::spawn(provide_progress(mp.clone(), rx)));
    let blobs = BlobsProtocol::new(
        &store,
        Some(EventSender::new(
            tx,
            EventMask {
                connected: ConnectMode::Notify,
                get: RequestMode::NotifyLog,
                ..EventMask::DEFAULT
            },
        )),
    );
    let (temp_tag, files, size) = import(paths, blobs.store(), &mp).await?;
    let rpc = listen_rpc(files);
    let router = Router::builder(endpoint).accept(TRANSFER_ALPN, blobs).accept(IRPC_ALPN, rpc).spawn();
    let ep = router.endpoint();
    time::timeout(Duration::from_secs(30), async move {
        if !matches!(relay, RelayMode::Disabled) {
            ep.online().await;
        }
    })
    .await?;
    let hash = temp_tag.hash();
    let addr = router.endpoint().addr();
    let ticket = BlobTicket::new(addr, hash, BlobFormat::HashSeq).to_string();
    let cancel = CancellationToken::new();
    {
        let mut tokens = TOKENS.lock();
        tokens.insert(ticket.clone(), cancel.clone());
    }
    match result.add(SendResult::ok(&ticket, size)) {
        Ok(_) => {}
        Err(_) => {
            if let Some(t) = TOKENS.lock().remove(&ticket) {
                t.cancel();
            }
        }
    }
    cancel.cancelled().await;
    TOKENS.lock().remove(&ticket);
    drop(temp_tag);
    time::timeout(Duration::from_secs(2), router.shutdown()).await??;
    drop(blobs_dir);
    drop(router);
    progress.await??;
    Ok(())
}

pub(super) fn cancel(ticket: Vec<u8>) -> Result<()> {
    let mut tokens = TOKENS.lock();
    if let Some(cancel) = tokens.remove(&decompress_ticket(ticket)?) {
        cancel.cancel();
    } else {
        return Err(anyhow!("token not found"));
    }
    Ok(())
}
