pub mod proto;
pub mod utils;

use std::{
    collections::BTreeMap,
    net::SocketAddr,
    path::PathBuf,
    str::FromStr,
    sync::{Arc, LazyLock},
    time::Duration,
};

use crate::{
    consts::{IRPC_ALPN, TRANSFER_ALPN},
    frb_generated::StreamSink,
    progress::{MultiProgress, Phase, ProgressObserver, ProgressState},
    services::send::{proto::SendServiceMessage, utils::import},
    types::BlobInfo,
    utils::{decompress_ticket, get_or_create_secret},
};
use crate::{services::send::proto::SendServiceProtocol, types::SendResult};

use anyhow::{anyhow, Result};
use hashbrown::HashMap;
use iroh::{endpoint::presets::Minimal, protocol::Router, Endpoint, RelayMap, RelayMode, RelayUrl};
use iroh_blobs::{
    provider::events::{ConnectMode, EventMask, EventSender, ProviderMessage},
    store::fs::FsStore,
    ticket::BlobTicket,
    BlobFormat, BlobsProtocol,
};
use irpc::{Client, WithChannels};
use irpc_iroh::IrohProtocol;
use parking_lot::{Mutex, RwLock};
use tempfile::{Builder, TempDir};
use tokio::{
    sync::mpsc::{self, Receiver},
    time,
};
use tokio_util::{sync::CancellationToken, task::AbortOnDropHandle};

static TOKENS: LazyLock<Mutex<HashMap<String, CancellationToken>>> =
    LazyLock::new(|| Mutex::new(HashMap::with_capacity(2)));

#[derive(Debug)]
pub(super) struct SendArgs {
    paths: Vec<PathBuf>,
    magic_addr: Option<SocketAddr>,
    relay: RelayMode,
}

impl SendArgs {
    pub fn new(
        paths: Vec<String>,
        magic_addr: Option<String>,
        relay: Option<String>,
    ) -> Result<Self> {
        let paths = paths
            .into_iter()
            .filter_map(|p| PathBuf::from(p).canonicalize().ok())
            .collect::<Vec<PathBuf>>();
        if paths.is_empty() {
            return Err(anyhow!("no valid paths provided"));
        }
        let magic_addr = magic_addr.map(|u| SocketAddr::from_str(&u)).transpose()?;
        let relay = relay
            .map(|u| {
                RelayUrl::from_str(&u).map(|url| RelayMode::Custom(RelayMap::from_iter(vec![url])))
            })
            .transpose()?
            .unwrap_or(RelayMode::Disabled);
        Ok(Self {
            paths,
            magic_addr,
            relay,
        })
    }
}

impl ProgressObserver for StreamSink<Vec<ProgressState>> {
    fn on_update(&self, state: Vec<ProgressState>) {
        let _ = self.add(state);
    }
}

fn tempdir_in(dir: PathBuf) -> Result<TempDir> {
    let dir = Builder::new()
        .prefix(".droplus-send-")
        .rand_bytes(6)
        .tempdir_in(dir)?;
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

async fn provide_progress(mp: Arc<MultiProgress>, mut recv: Receiver<ProviderMessage>) {
    let conns = Arc::new(RwLock::new(BTreeMap::new()));
    loop {
        match recv.recv().await {
            Some(item) => {
                match item {
                    ProviderMessage::ClientConnectedNotify(msg) => {
                        let id = mp.add(Phase::Uploading {
                            connection_id: msg.connection_id,
                        });
                        conns.write().insert(msg.connection_id, id);
                    }
                    ProviderMessage::ConnectionClosed(msg) => {
                        if let Some(id) = conns.write().remove(&msg.connection_id) {
                            mp.remove(&id);
                        }
                    }
                    _ => {}
                };
            }
            None => break,
        }
    }
}

pub(super) async fn start(
    args: SendArgs,
    stream: StreamSink<Vec<ProgressState>>,
    result: &StreamSink<SendResult>,
) -> Result<()> {
    let SendArgs {
        paths,
        magic_addr,
        relay,
    } = args;
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
                ..EventMask::DEFAULT
            },
        )),
    );
    let (temp_tag, files, size) = import(paths, blobs.store(), &mp).await?;
    let rpc = listen_rpc(files);
    let router = Router::builder(endpoint)
        .accept(TRANSFER_ALPN, blobs)
        .accept(IRPC_ALPN, rpc)
        .spawn();
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
    progress.await.ok();
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
