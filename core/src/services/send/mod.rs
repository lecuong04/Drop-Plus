pub mod utils;

use std::{
    collections::HashMap,
    net::{SocketAddrV4, SocketAddrV6},
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
    types::{BlobInfo, RelayModeOption},
    utils::get_or_create_secret,
};
use crate::{protos::SendServiceMessage, types::SendResult};

use anyhow::{anyhow, Result};
use iroh::{endpoint::presets::Minimal, protocol::Router, Endpoint, RelayMode, TransportAddr};
use iroh_blobs::{
    provider::events::{ConnectMode, EventMask, EventSender, ProviderMessage, RequestMode, RequestUpdate},
    store::fs::FsStore,
    ticket::BlobTicket,
    BlobFormat, BlobsProtocol,
};
use irpc::{Client, WithChannels};
use irpc_iroh::IrohProtocol;
use parking_lot::RwLock;
use tempfile::{Builder, TempDir};
use tokio::{
    sync::mpsc::{self, Receiver, UnboundedReceiver, UnboundedSender},
    task::JoinSet,
    time,
};
use tokio_util::{sync::CancellationToken, task::AbortOnDropHandle};
use tracing::error;
use uuid::Uuid;

static TOKENS: LazyLock<scc::HashMap<String, CancellationToken>> = LazyLock::new(scc::HashMap::new);

#[derive(Debug)]
pub(super) struct SendArgs {
    paths: Vec<PathBuf>,
    ipv4_addr: Option<SocketAddrV4>,
    ipv6_addr: Option<SocketAddrV6>,
    relay: RelayMode,
}

impl SendArgs {
    pub fn new(paths: Vec<String>, ipv4_addr: Option<String>, ipv6_addr: Option<String>, relay: RelayModeOption) -> Result<Self> {
        let paths = paths
            .into_iter()
            .map(|p| PathBuf::from(p).canonicalize().map_err(|e| anyhow!("{}", e)))
            .collect::<Result<Vec<PathBuf>>>()?;
        if paths.is_empty() {
            return Err(anyhow!("no valid paths provided"));
        }
        let ipv4_addr = ipv4_addr.map(|a| SocketAddrV4::from_str(&a)).transpose()?;
        let ipv6_addr = ipv6_addr.map(|a| SocketAddrV6::from_str(&a)).transpose()?;
        let relay = <Result<RelayMode>>::from(relay)?;
        Ok(Self {
            paths,
            ipv4_addr,
            ipv6_addr,
            relay,
        })
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

fn listen_rpc(files: Vec<BlobInfo>) -> (IrohProtocol<SendServiceProtocol>, AbortOnDropHandle<()>) {
    let (tx, rx) = mpsc::channel(16);
    let handle = AbortOnDropHandle::new(tokio::task::spawn(actor(rx, files)));
    let client = Client::<SendServiceProtocol>::local(tx);
    let rpc = IrohProtocol::with_sender(client.as_local().unwrap());
    (rpc, handle)
}

async fn request_progress(
    request_id: u64,
    connection_id: u64,
    hashes: Arc<RwLock<HashMap<u64, HashMap<u64, u64>>>>,
    utx: UnboundedSender<TransferState>,
    mut rx: irpc::channel::mpsc::Receiver<RequestUpdate>,
    cancel: CancellationToken,
) {
    if request_id != 0 {
        let (mut index, mut size) = (0, 0);
        loop {
            tokio::select! {
                res = rx.recv() => {
                    match res {
                        Ok(Some(r)) => {
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
                                    utx.send(TransferState::new(connection_id, index, true, false)).unwrap();
                                }
                                RequestUpdate::Aborted(_) => {
                                    utx.send(TransferState::new(connection_id, index, false, true)).unwrap();
                                }
                            }
                        }
                        _ => break,
                    }
                }
                _ = cancel.cancelled() => {
                    break;
                }
            }
        }
    } else {
        let mut map = HashMap::new();
        loop {
            tokio::select! {
                res = rx.recv() => {
                    match res {
                        Ok(Some(r)) => {
                            match r {
                                RequestUpdate::Started(r) => {
                                    map.insert(r.index, r.size);
                                }
                                RequestUpdate::Completed(_) => {
                                    hashes.write().insert(connection_id, map.clone());
                                }
                                _ => {}
                            }
                        }
                        _ => break,
                    }
                }
                _ = cancel.cancelled() => {
                    break;
                }
            }
        }
    }
}

async fn update_progress(
    mp: Arc<MultiProgress>,
    hashes: Arc<RwLock<HashMap<u64, HashMap<u64, u64>>>>,
    connections: Arc<RwLock<HashMap<u64, (Uuid, String)>>>,
    mut urx: UnboundedReceiver<TransferState>,
) {
    let mut map = HashMap::new();
    while let Some(s) = urx.recv().await {
        let value = connections.read().get(&s.connection_id).cloned();
        match value {
            Some((id, endpoint)) => {
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
                            endpoint,
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

async fn provide_progress(mp: Arc<MultiProgress>, mut recv: Receiver<ProviderMessage>, cancel: CancellationToken) -> Result<()> {
    let connections = Arc::new(RwLock::new(HashMap::new()));
    let hashes = Arc::new(RwLock::new(HashMap::new()));
    let (utx, urx) = mpsc::unbounded_channel();
    let handle = AbortOnDropHandle::new(tokio::task::spawn(update_progress(mp.clone(), hashes.clone(), connections.clone(), urx)));
    let mut tasks = JoinSet::new();
    loop {
        tokio::select! {
            item = recv.recv() => {
                match item {
                    Some(item) => {
                        match item {
                            ProviderMessage::ClientConnectedNotify(msg) => {
                                if let Some(endpoint) = msg.endpoint_id {
                                    let endpoint = endpoint.fmt_short().to_string();
                                    let connection_id = msg.connection_id;
                                    let id = mp.add(Phase::Uploading {
                                        endpoint: endpoint.clone(),
                                        is_failed: false,
                                        is_completed: false,
                                    });
                                    connections.write().insert(connection_id, (id, endpoint));
                                };
                            }
                            ProviderMessage::GetRequestReceivedNotify(msg) => {
                                tasks.spawn(request_progress(msg.request_id, msg.connection_id, hashes.clone(), utx.clone(), msg.rx, cancel.clone()));
                            }
                            _ => {}
                        };
                    }
                    None => break,
                }
            }
            _ = cancel.cancelled() => {
                break;
            }
        }
    }
    while let Some(task) = tasks.join_next().await {
        task?
    }
    handle.await?;
    Ok(())
}

pub(super) async fn start(args: SendArgs, stream: StreamSink<Vec<ProgressState>>, result: &StreamSink<SendResult>) -> Result<()> {
    let SendArgs {
        paths,
        ipv4_addr,
        ipv6_addr,
        relay,
    } = args;
    let secret_key = get_or_create_secret()?;
    let mut builder = Endpoint::builder(Minimal)
        .alpns(vec![TRANSFER_ALPN.to_vec()])
        .secret_key(secret_key)
        .relay_mode(relay.clone());
    if let (Some(ipv4_addr), Some(ipv6_addr)) = (ipv4_addr, ipv6_addr) {
        builder = builder.clear_ip_transports();
        builder = builder.bind_addr(ipv4_addr)?;
        builder = builder.bind_addr(ipv6_addr)?;
    } else if let Some(ipv4_addr) = ipv4_addr {
        builder = builder.clear_ip_transports();
        builder = builder.bind_addr(ipv4_addr)?;
    } else if let Some(ipv6_addr) = ipv6_addr {
        builder = builder.clear_ip_transports();
        builder = builder.bind_addr(ipv6_addr)?;
    }
    let blobs_dir = tempdir_in(std::env::temp_dir())?;
    let mp = Arc::new(MultiProgress::new(Arc::new(stream)));
    let endpoint = builder.bind().await?;
    let store = FsStore::load(blobs_dir.path()).await?;
    let (tx, rx) = mpsc::channel(128);
    let cancel = CancellationToken::new();
    let progress = AbortOnDropHandle::new(tokio::task::spawn(provide_progress(mp.clone(), rx, cancel.clone())));
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
    let (rpc, handle) = listen_rpc(files);
    let router = Router::builder(endpoint).accept(TRANSFER_ALPN, blobs).accept(IRPC_ALPN, rpc).spawn();
    let ep = router.endpoint();
    time::timeout(Duration::from_secs(30), async move {
        if !matches!(relay, RelayMode::Disabled) {
            let id = mp.add(Phase::Connecting);
            ep.online().await;
            mp.remove(&id);
        }
    })
    .await?;
    let hash = temp_tag.hash();
    let addr = router.endpoint().addr();
    let ticket = BlobTicket::new(addr.clone(), hash, BlobFormat::HashSeq).to_string();
    let addrs = addr
        .addrs
        .iter()
        .map(|a| match a {
            TransportAddr::Relay(relay_url) => relay_url.to_string(),
            TransportAddr::Ip(socket_addr) => socket_addr.to_string(),
            TransportAddr::Custom(custom_addr) => custom_addr.to_string(),
            _ => "".to_string(),
        })
        .collect::<Vec<String>>();
    let _ = TOKENS.insert_sync(ticket.clone(), cancel.clone());
    match result.add(SendResult::ok(&ticket, size, addrs)) {
        Ok(_) => {}
        Err(_) => {
            if let Some((_, t)) = TOKENS.remove_sync(&ticket) {
                t.cancel();
            }
        }
    }
    cancel.cancelled().await;
    TOKENS.remove_sync(&ticket);
    drop(temp_tag);
    time::timeout(Duration::from_secs(2), router.shutdown()).await??;
    drop(blobs_dir);
    drop(router);
    progress.await??;
    handle.await?;
    Ok(())
}

pub(super) fn cancel(ticket: String) -> Result<()> {
    if let Some((_, cancel)) = TOKENS.remove_sync(&ticket) {
        cancel.cancel();
        Ok(())
    } else {
        Err(anyhow!("token not found"))
    }
}
