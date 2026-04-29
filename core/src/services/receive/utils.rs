use std::path::{Path, PathBuf};

use anyhow::{bail, Result};
use futures_buffered::BufferedStreamExt;
use futures_util::StreamExt;
use iroh_blobs::{
    api::{
        blobs::{ExportMode, ExportOptions, ExportProgressItem},
        Store,
    },
    format::collection::Collection,
};

use crate::{
    progresses::{MultiProgress, Phase},
    utils::PARALLELISM,
};

fn validate_path_component(component: &str) -> Result<()> {
    anyhow::ensure!(!component.contains('/'), "path components must not contain the only correct path separator, /");
    Ok(())
}

fn get_export_path(root: &Path, name: &str) -> Result<PathBuf> {
    let parts = name.split('/');
    let mut path = root.to_path_buf();
    for part in parts {
        validate_path_component(part)?;
        path.push(part);
    }
    Ok(path)
}

pub async fn export(root: &Path, db: &Store, collection: Collection, mp: &MultiProgress) -> Result<()> {
    futures_util::stream::iter(collection.iter())
        .map(|(name, hash)| {
            let root = root.to_path_buf();
            let db = db.clone();
            let mp = mp.clone();
            let name = name.clone();
            let hash = *hash;
            async move {
                let target = get_export_path(&root, &name)?;
                if target.exists() {
                    let now = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .map_err(|e| anyhow::anyhow!("Time went backwards: {}", e))?
                        .as_secs();
                    let mut new_target = target.clone();
                    let file_name = target.file_name().ok_or_else(|| anyhow::anyhow!("invalid target file name"))?.to_string_lossy();
                    new_target.set_file_name(format!("{}.{}", file_name, now));
                    if let Err(e) = tokio::fs::rename(&target, &new_target).await {
                        bail!("failed to rename existing file {} to {}: {}", target.display(), new_target.display(), e);
                    }
                }
                let id = mp.add(Phase::Exporting { name: name.clone() });
                let mut stream = db
                    .export_with_opts(ExportOptions {
                        hash,
                        target,
                        mode: ExportMode::Copy,
                    })
                    .stream()
                    .await;
                while let Some(item) = stream.next().await {
                    match item {
                        ExportProgressItem::Size(size) => {
                            mp.set_length(&id, size);
                        }
                        ExportProgressItem::CopyProgress(offset) => {
                            mp.set_position(&id, offset);
                        }
                        ExportProgressItem::Done => {
                            mp.remove(&id);
                        }
                        ExportProgressItem::Error(cause) => {
                            mp.remove(&id);
                            bail!("error exporting {}: {}", name, cause);
                        }
                    }
                }
                Ok(())
            }
        })
        .buffered_unordered(*PARALLELISM)
        .collect::<Vec<Result<()>>>()
        .await
        .into_iter()
        .collect::<Result<Vec<()>>>()?;
    Ok(())
}
