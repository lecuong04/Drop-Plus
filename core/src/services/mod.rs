pub mod others;
pub mod receive;
pub mod send;

use std::sync::LazyLock;

use anyhow::Result;
use tokio::{runtime::Runtime, task::block_in_place};
use tracing::instrument;

use crate::{
    frb_generated::StreamSink,
    progresses::ProgressState,
    services::{others::qr, receive::ReceiveArgs, send::SendArgs},
    types::{ReceiveResult, SendResult},
};

static RUNTIME: LazyLock<Runtime> = LazyLock::new(|| Runtime::new().expect("failed to initialize tokio runtime"));

#[instrument(err, skip(stream, result))]
pub fn send(paths: Vec<String>, magic_addr: Option<String>, relay: Option<String>, stream: StreamSink<Vec<ProgressState>>, result: StreamSink<SendResult>) -> Result<()> {
    let handle = RUNTIME.handle().clone();
    block_in_place(|| {
        handle
            .block_on(async {
                let args = SendArgs::new(paths, magic_addr, relay)?;
                self::send::start(args, stream, &result).await
            })
            .inspect_err(|_| {
                let _ = result.add(SendResult::err());
            })
    })
}

#[instrument(err)]
pub fn cancel_send(ticket: Vec<u8>) -> Result<()> {
    self::send::cancel(ticket)
}

#[instrument(err, skip(stream, result))]
pub fn receive(ticket: Vec<u8>, download_dir: String, relay: Option<String>, stream: StreamSink<Vec<ProgressState>>, result: StreamSink<ReceiveResult>) -> Result<()> {
    let handle = RUNTIME.handle().clone();
    block_in_place(|| {
        handle
            .block_on(async {
                let args = ReceiveArgs::new(ticket, download_dir, relay)?;
                self::receive::start(args, stream, &result).await
            })
            .inspect_err(|_| {
                let _ = result.add(ReceiveResult::err());
            })
    })
}

#[instrument(err)]
pub fn accept_receive(ticket: Vec<u8>) -> Result<()> {
    self::receive::accept(ticket)
}

#[instrument(err)]
pub fn reject_receive(ticket: Vec<u8>) -> Result<()> {
    self::receive::reject(ticket)
}

#[instrument(err)]
pub fn cancel_receive(ticket: Vec<u8>) -> Result<()> {
    self::receive::cancel(ticket)
}

#[instrument(err)]
pub fn qr_reader(image: Vec<u8>) -> Result<Vec<u8>> {
    qr::reader(image)
}
