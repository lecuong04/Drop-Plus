use std::{
    collections::HashMap,
    time::{SystemTime, UNIX_EPOCH},
};

use serde::{Deserialize, Serialize};

pub enum SendResult {
    Ok { ticket: String, size: u64 },
    Err,
}

impl SendResult {
    pub fn ok(ticket: &String, size: u64) -> Self {
        Self::Ok { ticket: ticket.clone(), size }
    }

    pub fn err() -> Self {
        Self::Err
    }
}

pub enum ReceiveResult {
    Pending { files: Vec<BlobInfo> },
    Ok { total_files: u64, payload_size: u64, elapsed_secs: u64 },
    Err,
}

impl ReceiveResult {
    pub fn ok(total_files: u64, payload_size: u64, elapsed: u64) -> Self {
        Self::Ok {
            total_files,
            payload_size,
            elapsed_secs: elapsed,
        }
    }

    pub fn pending(files: Vec<BlobInfo>) -> Self {
        Self::Pending { files }
    }

    pub fn err() -> Self {
        Self::Err
    }
}

#[derive(Clone)]
pub struct LogEntry {
    pub time: u64,
    pub level: String,
    pub target: String,
    pub data: HashMap<String, String>,
}

impl LogEntry {
    pub fn new(level: String, target: String, data: HashMap<String, String>) -> Self {
        Self {
            time: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_millis() as u64,
            level,
            target,
            data,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlobInfo {
    pub name: String,
    pub size: u64,
}

impl BlobInfo {
    pub fn new(name: String, size: u64) -> Self {
        Self { name, size }
    }
}
