use std::{
    path::{Component, Path, PathBuf},
    sync::atomic::{AtomicUsize, Ordering},
};

use anyhow::{anyhow, bail, Context, Result};
use futures_buffered::BufferedStreamExt;
use futures_util::StreamExt;
use iroh_blobs::{
    api::{
        blobs::{AddPathOptions, AddProgressItem, ImportMode},
        Store, TempTag,
    },
    format::collection::Collection,
    BlobFormat,
};
use tracing::instrument;
use walkdir::WalkDir;

use crate::{
    progresses::{MultiProgress, Phase},
    types::BlobInfo,
    utils::PARALLELISM,
};

fn canonicalized_path_to_string(path: impl AsRef<Path>, must_be_relative: bool) -> Result<String> {
    let mut parts = Vec::new();
    for component in path.as_ref().components() {
        match component {
            Component::Normal(segment) => {
                let segment = segment.to_str().ok_or_else(|| anyhow!("invalid character in path"))?;
                parts.push(segment);
            }
            Component::RootDir => {
                if must_be_relative {
                    return Err(anyhow!("invalid path component {:?}", component));
                }
                parts.push("");
            }
            _ => return Err(anyhow!("invalid path component {:?}", component)),
        }
    }
    let res = parts.join("/");
    if !must_be_relative && res.is_empty() {
        Ok("/".to_string())
    } else {
        Ok(res)
    }
}

#[instrument(err)]
fn process_path(path: &PathBuf) -> Result<Vec<(String, PathBuf)>> {
    let path = path.canonicalize()?;
    let root = path.parent().context("context get parent")?;
    let files = WalkDir::new(&path).into_iter();
    let sources = files
        .map(|entry| {
            let entry = entry?;
            if !entry.file_type().is_file() {
                return Ok(None);
            }
            let path = entry.into_path();
            let relative = path.strip_prefix(root)?;
            let name = canonicalized_path_to_string(relative, true)?;
            Ok(Some((name, path)))
        })
        .filter_map(Result::transpose)
        .collect::<Result<Vec<_>>>()?;
    Ok(sources)
}

#[instrument(err, skip(mp))]
pub(super) async fn import(paths: Vec<PathBuf>, db: &Store, mp: &MultiProgress) -> Result<(TempTag, Vec<BlobInfo>, u64)> {
    let error_count = AtomicUsize::new(0);
    let data_sources: Vec<(String, PathBuf)> = paths
        .iter()
        .filter_map(|path| match process_path(path) {
            Ok(sources) => Some(sources),
            Err(_) => {
                error_count.fetch_add(1, Ordering::Relaxed);
                None
            }
        })
        .flatten()
        .collect();
    if error_count.load(Ordering::Relaxed) > 0 {
        return Err(anyhow!("failed to process {} path(s)", error_count.load(Ordering::Relaxed)));
    }
    if data_sources.is_empty() {
        return Err(anyhow!("no files found to share"));
    }
    let names_and_tags = futures_util::stream::iter(data_sources)
        .map(|(name, path)| async move {
            let id = mp.add(Phase::Importing { name: name.clone() });
            let import = db.add_path_with_opts(AddPathOptions {
                path,
                mode: ImportMode::TryReference,
                format: BlobFormat::Raw,
            });
            let mut stream = import.stream().await;
            let mut item_size = 0;
            let temp_tag = loop {
                let item = stream.next().await.context("import stream ended without a tag")?;
                match item {
                    AddProgressItem::Size(size) => {
                        item_size = size;
                        mp.set_length(&id, size);
                    }
                    AddProgressItem::CopyProgress(offset) => mp.set_position(&id, offset),
                    AddProgressItem::CopyDone => mp.set_position(&id, 0),
                    AddProgressItem::OutboardProgress(offset) => mp.set_position(&id, offset),
                    AddProgressItem::Error(cause) => {
                        mp.remove(&id);
                        bail!("error importing {}: {}", name, cause);
                    }
                    AddProgressItem::Done(tt) => {
                        mp.remove(&id);
                        break tt;
                    }
                }
            };
            Ok((name, temp_tag, item_size))
        })
        .buffered_unordered(*PARALLELISM)
        .collect::<Vec<_>>()
        .await;
    let mut names_and_tags = names_and_tags.into_iter().collect::<Result<Vec<_>>>()?;
    names_and_tags.sort_unstable_by(|(a, _, _), (b, _, _)| a.cmp(b));
    let size = names_and_tags.iter().map(|(_, _, size)| *size).sum::<u64>();
    let (collection, files) = names_and_tags
        .into_iter()
        .map(|(name, tag, size)| ((name.clone(), tag.hash()), BlobInfo::new(name, size)))
        .unzip::<_, _, Collection, Vec<_>>();
    let temp_tag = collection.store(db).await?;
    Ok((temp_tag, files, size))
}
