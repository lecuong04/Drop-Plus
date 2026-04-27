use irpc::{channel::oneshot, rpc_requests};
use serde::{Deserialize, Serialize};

use crate::types::BlobInfo;

#[rpc_requests(message = SendServiceMessage)]
#[derive(Debug, Serialize, Deserialize)]
pub enum SendServiceProtocol {
    #[rpc(tx = oneshot::Sender<Vec<BlobInfo>>)]
    #[wrap(ListFiles, derive(Clone))]
    ListFiles,
}
