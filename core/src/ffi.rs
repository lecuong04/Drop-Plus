use std::{collections::HashMap, io, sync::OnceLock};

use flutter_rust_bridge::{frb, setup_default_user_utils};
use tokio::sync::broadcast::{self, Sender};
use tracing::{
    field::{Field, Visit},
    level_filters::LevelFilter,
    Level,
};
use tracing_subscriber::{fmt, layer::SubscriberExt, Layer, Registry};

use crate::{
    frb_generated::StreamSink,
    progresses::ProgressState,
    services::{self},
    types::{LogEntry, ReceiveResult, SendResult},
};

use anyhow::Result;

struct CoreVisitor(HashMap<String, String>);

impl Visit for CoreVisitor {
    fn record_debug(&mut self, field: &Field, value: &dyn std::fmt::Debug) {
        self.0.insert(field.name().into(), format!("{value:?}"));
    }
}

struct CoreLayer {
    tx: Sender<LogEntry>,
}

impl CoreLayer {
    fn new(tx: Sender<LogEntry>) -> Self {
        Self { tx }
    }

    fn level_str(level: &Level) -> &'static str {
        match *level {
            Level::TRACE => "TRACE",
            Level::DEBUG => "DEBUG",
            Level::INFO => "INFO",
            Level::WARN => "WARN",
            Level::ERROR => "ERROR",
        }
    }
}

impl<S> Layer<S> for CoreLayer
where
    S: tracing::Subscriber,
{
    fn on_event(&self, event: &tracing::Event<'_>, _ctx: tracing_subscriber::layer::Context<'_, S>) {
        let mut visitor = CoreVisitor(HashMap::new());
        event.record(&mut visitor);
        let entry = LogEntry::new(Self::level_str(event.metadata().level()).to_string(), event.metadata().target().into(), visitor.0);
        let _ = self.tx.send(entry);
    }
}

static LOG_TX: OnceLock<Sender<LogEntry>> = OnceLock::new();

#[frb(init)]
pub fn init_app() {
    setup_default_user_utils();
}

#[frb(name = "initTracing")]
pub async fn init_tracing(stream: StreamSink<LogEntry>) {
    let mut rx = match LOG_TX.get() {
        Some(tx) => tx.subscribe(),
        None => {
            let (tx, _) = broadcast::channel(256);
            let is_debug = cfg!(debug_assertions);
            let (file, line_number, level) = if is_debug {
                (true, true, LevelFilter::DEBUG)
            } else {
                (false, false, LevelFilter::INFO)
            };
            let fmt_layer = fmt::layer().with_file(file).with_line_number(line_number).with_writer(io::stderr).with_filter(level);
            tracing::subscriber::set_global_default(Registry::default().with(fmt_layer).with(CoreLayer::new(tx.clone()))).unwrap();
            LOG_TX.get_or_init(|| tx.clone()).subscribe()
        }
    };
    while let Ok(l) = rx.recv().await {
        let _ = stream.add(l);
    }
}

#[frb(name = "send")]
pub fn send(paths: Vec<String>, addr: Option<String>, relay: Option<String>, stream: StreamSink<Vec<ProgressState>>, result: StreamSink<SendResult>) -> Result<()> {
    services::send(paths, addr, relay, stream, result)
}

#[frb(name = "cancelSend")]
pub fn cancel_send(ticket: String) -> Result<()> {
    services::cancel_send(ticket)
}

#[frb(name = "receive")]
pub fn receive(ticket: String, download_dir: String, relay: Option<String>, stream: StreamSink<Vec<ProgressState>>, result: StreamSink<ReceiveResult>) -> Result<()> {
    services::receive(ticket, download_dir, relay, stream, result)
}

#[frb(name = "acceptReceive")]
pub fn accept_receive(ticket: String) -> Result<()> {
    services::accept_receive(ticket)
}

#[frb(name = "rejectReceive")]
pub fn reject_receive(ticket: String) -> Result<()> {
    services::reject_receive(ticket)
}

#[frb(name = "cancelReceive")]
pub fn cancel_receive(ticket: String) -> Result<()> {
    services::cancel_receive(ticket)
}

#[frb(name = "qrReader")]
pub fn qr_reader(image: Vec<u8>) -> Result<Vec<u8>> {
    services::qr_reader(image)
}

#[frb(name = "getAddrs")]
pub fn get_addrs() -> Result<HashMap<String, String>> {
    services::get_addrs()
}
