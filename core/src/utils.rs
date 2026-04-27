use std::{str::FromStr, sync::LazyLock};

use anyhow::{anyhow, Context, Result};
use iroh::SecretKey;
use miniz_oxide::inflate::decompress_to_vec;

pub static PARALLELISM: LazyLock<usize> = LazyLock::new(|| num_cpus::get().min(8));

pub fn get_or_create_secret() -> Result<SecretKey> {
    match std::env::var("DROPLUS_SECRET") {
        Ok(s) => SecretKey::from_str(&s).context("invalid secret"),
        Err(_) => Ok(SecretKey::generate()),
    }
}

pub fn decompress_ticket(ticket: Vec<u8>) -> Result<String> {
    let ticket = decompress_to_vec(&ticket).map_err(|e| anyhow!("invalid ticket: {e}"))?;
    String::from_utf8(ticket).context("ticket payload is not valid UTF-8")
}
