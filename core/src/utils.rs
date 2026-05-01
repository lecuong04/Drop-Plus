use std::{str::FromStr, sync::LazyLock};

use anyhow::{Context, Result};
use iroh::SecretKey;

pub static PARALLELISM: LazyLock<usize> = LazyLock::new(|| num_cpus::get().min(8));

pub fn get_or_create_secret() -> Result<SecretKey> {
    match std::env::var("DROPLUS_SECRET") {
        Ok(s) => SecretKey::from_str(&s).context("invalid secret"),
        Err(_) => Ok(SecretKey::generate()),
    }
}
