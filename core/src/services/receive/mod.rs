pub mod utils;

use std::{
    path::PathBuf,
    str::FromStr,
    sync::{Arc, LazyLock},
    time::Duration,
};

use anyhow::{anyhow, bail, Result};
use futures_util::StreamExt;
use iroh::{endpoint::presets::Minimal, Endpoint, EndpointAddr, RelayMap, RelayMode, RelayUrl, SecretKey};
use iroh_blobs::{
    api::remote::GetProgressItem,
    format::collection::Collection,
    get::{request::get_hash_seq_and_sizes, GetError, Stats},
    store::fs::FsStore,
    ticket::BlobTicket,
};
use irpc::Client;
use scc::HashMap;
use tokio::{
    select,
    sync::oneshot,
    time::{timeout, Instant},
};
use tokio_util::sync::CancellationToken;
use tracing::warn;

use crate::{
    consts::{IRPC_ALPN, TRANSFER_ALPN},
    frb_generated::StreamSink,
    progresses::{MultiProgress, Phase, ProgressState},
    protos::{ListFiles, SendServiceProtocol},
    services::receive::utils::export,
    types::ReceiveResult,
};

static TOKENS: LazyLock<HashMap<String, CancellationToken>> = LazyLock::new(HashMap::new);

static PENDING_RECEIVES: LazyLock<HashMap<String, oneshot::Sender<bool>>> = LazyLock::new(HashMap::new);

#[derive(Debug)]
pub(super) struct ReceiveArgs {
    ticket: BlobTicket,
    relay: RelayMode,
    download_dir: PathBuf,
}

impl ReceiveArgs {
    pub fn new(ticket: String, download_dir: String, relay: Option<String>) -> Result<Self> {
        let ticket = BlobTicket::from_str(&ticket)?;
        let download_dir = PathBuf::from_str(&download_dir)?;
        let relay = relay
            .map(|u| RelayUrl::from_str(&u).map(|url| RelayMode::Custom(RelayMap::from_iter(vec![url]))))
            .transpose()?
            .unwrap_or(RelayMode::Disabled);
        Ok(Self { download_dir, relay, ticket })
    }
}

fn show_get_error(e: GetError) -> GetError {
    match &e {
        GetError::InitialNext { source, .. } => warn!(error = %source, "initial connection error"),
        GetError::ConnectedNext { source, .. } => warn!(error = %source, "connected error"),
        GetError::AtBlobHeaderNext { source, .. } => {
            warn!(error = %source, "reading blob header error")
        }
        GetError::Decode { source, .. } => warn!(error = %source, "decoding error"),
        GetError::IrpcSend { source, .. } => warn!(error = %source, "error sending over irpc"),
        GetError::AtClosingNext { source, .. } => warn!(error = %source, "error at closing"),
        GetError::BadRequest { .. } => warn!("bad request"),
        GetError::LocalFailure { source, .. } => {
            warn!(error = ?source, "local failure")
        }
    }
    e
}

fn connect_rpc(endpoint: &Endpoint, addr: &EndpointAddr) -> Client<SendServiceProtocol> {
    irpc_iroh::client(endpoint.clone(), addr.clone(), IRPC_ALPN)
}

pub(super) async fn start(args: ReceiveArgs, secret_key: SecretKey, stream: StreamSink<Vec<ProgressState>>, result: &StreamSink<ReceiveResult>) -> Result<()> {
    let ReceiveArgs { ticket, relay, download_dir } = args;
    let addr = ticket.addr().clone();
    let hash_and_format = ticket.hash_and_format();
    let builder = Endpoint::builder(Minimal)
        .alpns(vec![TRANSFER_ALPN.to_vec()])
        .secret_key(secret_key)
        .relay_mode(relay.clone());
    let endpoint = builder.bind().await?;
    let mp: MultiProgress = MultiProgress::new(Arc::new(stream));
    let id = mp.add(Phase::Pending);
    let client = connect_rpc(&endpoint, &addr);
    let files = timeout(Duration::from_secs(5), client.rpc(ListFiles)).await??;
    result.add(ReceiveResult::pending(files)).map_err(|e| anyhow!("{}", e))?;
    let (tx, rx) = oneshot::channel();
    let _ = PENDING_RECEIVES.insert_sync(ticket.to_string(), tx);
    let accepted = rx.await.unwrap_or(false);
    PENDING_RECEIVES.remove_sync(&ticket.to_string());
    if !accepted {
        return Ok(());
    }
    let data_dir = download_dir.join(format!(".droplus-recv-{}", hash_and_format.hash.fmt_short().to_lowercase()));
    let db = FsStore::load(&data_dir).await?;
    let receive_result = async {
        let cancel = CancellationToken::new();
        let _ = TOKENS.insert_sync(ticket.to_string(), cancel.clone());
        let local = db.remote().local(hash_and_format).await?;
        let (stats, total_files, payload_size) = if !local.is_complete() {
            mp.change_phase(&id, Phase::Connecting, None);
            let connection = select! {
                res = timeout(Duration::from_secs(10), endpoint.connect(addr, TRANSFER_ALPN)) => {
                    match res {
                        Ok(Ok(connection)) => Ok(connection),
                        Ok(Err(e)) => Err(anyhow!("connect failed: {}", e)),
                        Err(_) => Err(anyhow!("timeout")),
                    }
                }
                _ = cancel.cancelled() => Err(anyhow!("cancelled"))
            }?;
            mp.change_phase(&id, Phase::Validating, None);
            let (_, sizes) = get_hash_seq_and_sizes(&connection, &hash_and_format.hash, 1024 * 1024 * 32, None)
                .await
                .map_err(show_get_error)?;
            let total_size = sizes.iter().copied().sum::<u64>();
            let total_files = (sizes.len().saturating_sub(1)) as u64;
            let local_size = local.local_bytes();
            let get = db.remote().execute_get(connection, local.missing());
            let mut stats = Stats::default();
            let mut completed = false;
            mp.change_phase(&id, Phase::Downloading, None);
            mp.set_length(&id, total_size);
            let mut stream = get.stream();
            while let Some(item) = stream.next().await {
                match item {
                    GetProgressItem::Progress(offset) => {
                        if cancel.is_cancelled() {
                            break;
                        }
                        mp.set_position(&id, local_size + offset);
                    }
                    GetProgressItem::Done(value) => {
                        stats = value;
                        completed = true;
                        break;
                    }
                    GetProgressItem::Error(cause) => {
                        mp.remove(&id);
                        bail!(show_get_error(cause));
                    }
                }
            }
            mp.remove(&id);
            if !completed {
                TOKENS.remove_sync(&ticket.to_string());
                bail!("download stream ended before completion");
            }
            (stats, total_files, total_size)
        } else {
            let total_files = local
                .children()
                .ok_or_else(|| anyhow!("missing child metadata for completed collection"))?
                .saturating_sub(1);
            (Stats::default(), total_files, 0)
        };
        let start = Instant::now();
        let collection = Collection::load(hash_and_format.hash, db.as_ref()).await?;
        export(&download_dir, &db, collection, &mp).await?;
        Ok((total_files, payload_size, stats.elapsed.as_secs() + start.elapsed().as_secs()))
    }
    .await;
    endpoint.close().await;
    db.shutdown().await?;
    match receive_result {
        Ok(x) => {
            result.add(ReceiveResult::ok(x.0, x.1, x.2)).map_err(|e| anyhow!("{}", e))?;
            tokio::fs::remove_dir_all(data_dir).await?;
        }
        Err(e) => {
            bail!(e);
        }
    };
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

pub(super) fn reject(ticket: String) -> Result<()> {
    if let Some((_, tx)) = PENDING_RECEIVES.remove_sync(&ticket) {
        let _ = tx.send(false);
    }
    Ok(())
}

pub(super) fn accept(ticket: String) -> Result<()> {
    if let Some((_, tx)) = PENDING_RECEIVES.remove_sync(&ticket) {
        let _ = tx.send(true);
    }
    Ok(())
}
