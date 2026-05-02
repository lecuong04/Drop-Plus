pub mod others;
pub mod receive;
pub mod send;

use std::{collections::HashMap, sync::LazyLock};

use anyhow::Result;
use iroh::SecretKey;
use tokio::{runtime::Runtime, task::block_in_place};
use tracing::instrument;

use crate::{
    frb_generated::StreamSink,
    progresses::ProgressState,
    services::{
        others::{addrs, qr},
        receive::ReceiveArgs,
        send::SendArgs,
    },
    types::{ReceiveResult, RelayModeOption, SendResult},
    utils::get_or_create_secret,
};

static RUNTIME: LazyLock<Runtime> = LazyLock::new(|| Runtime::new().expect("failed to initialize tokio runtime"));
static SECRET_KEY: LazyLock<SecretKey> = LazyLock::new(|| get_or_create_secret().expect("failed to initialize secret key"));

#[instrument(err, skip(stream, result))]
pub fn send(
    paths: Vec<String>,
    ipv4_addr: Option<String>,
    ipv6_addr: Option<String>,
    relay: RelayModeOption,
    stream: StreamSink<Vec<ProgressState>>,
    result: StreamSink<SendResult>,
) -> Result<()> {
    let handle = RUNTIME.handle().clone();
    block_in_place(|| {
        handle
            .block_on(async {
                let args = SendArgs::new(paths, ipv4_addr, ipv6_addr, relay)?;
                self::send::start(args, SECRET_KEY.clone(), stream, &result).await
            })
            .inspect_err(|_| {
                let _ = result.add(SendResult::err());
            })
    })
}

#[instrument(err)]
pub fn cancel_send(ticket: String) -> Result<()> {
    self::send::cancel(ticket)
}

#[instrument(err, skip(stream, result))]
pub fn receive(ticket: String, download_dir: String, relay: Option<String>, stream: StreamSink<Vec<ProgressState>>, result: StreamSink<ReceiveResult>) -> Result<()> {
    let handle = RUNTIME.handle().clone();
    block_in_place(|| {
        handle
            .block_on(async {
                let args = ReceiveArgs::new(ticket, download_dir, relay)?;
                self::receive::start(args, SECRET_KEY.clone(), stream, &result).await
            })
            .inspect_err(|_| {
                let _ = result.add(ReceiveResult::err());
            })
    })
}

#[instrument(err)]
pub fn accept_receive(ticket: String) -> Result<()> {
    self::receive::accept(ticket)
}

#[instrument(err)]
pub fn reject_receive(ticket: String) -> Result<()> {
    self::receive::reject(ticket)
}

#[instrument(err)]
pub fn cancel_receive(ticket: String) -> Result<()> {
    self::receive::cancel(ticket)
}

#[instrument(err)]
pub fn qr_reader(image: Vec<u8>) -> Result<Vec<u8>> {
    qr::reader(image)
}

#[instrument(err)]
pub fn get_addrs() -> Result<HashMap<String, String>> {
    addrs::get()
}
