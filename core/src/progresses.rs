use scc::HashMap;
use std::{sync::Arc, time::Duration};

use parking_lot::Mutex;
use tokio::{runtime::Handle, time};
use uuid::Uuid;

const PROGRESS_DEBOUNCE: Duration = Duration::from_millis(200);

#[derive(Debug, Clone, PartialEq)]
pub enum Phase {
    Importing { name: String },
    Uploading { endpoint: String, is_completed: bool, is_failed: bool },
    Pending,
    Connecting,
    Validating,
    Downloading,
    Exporting { name: String },
}

#[derive(Debug, Clone)]
pub struct ProgressState {
    pub phase: Phase,
    pub position: u64,
    pub length: Option<u64>,
}

#[derive(Clone)]
pub struct MultiProgress {
    state: Arc<HashMap<Uuid, ProgressState>>,
    observer: Arc<dyn ProgressObserver>,
    debounce: Arc<Mutex<DebounceMeta>>,
    debounce_window: Duration,
}

pub trait ProgressObserver: Send + Sync {
    fn on_update(&self, state: Vec<ProgressState>);
}

#[derive(Default)]
struct DebounceMeta {
    dirty: bool,
    scheduled: bool,
}

impl MultiProgress {
    pub fn new(observer: Arc<dyn ProgressObserver>) -> Self {
        Self {
            state: Arc::new(HashMap::with_capacity(4)),
            observer,
            debounce: Arc::new(Mutex::new(DebounceMeta::default())),
            debounce_window: PROGRESS_DEBOUNCE,
        }
    }

    pub fn add(&self, phase: Phase) -> Uuid {
        let id = Uuid::now_v7();
        let _ = self.state.insert_sync(id, Self::new_state(phase, None));
        self.notify_immediate();
        id
    }

    pub fn change_phase(&self, id: &Uuid, phase: Phase, position: Option<u64>) {
        if self.update_state(id, |state| {
            *state = Self::new_state(phase.clone(), position);
            true
        }) {
            self.notify_immediate();
        }
    }

    pub fn increase(&self, id: &Uuid, delta: u64) -> u64 {
        let mut output = 0;
        if self.update_state(id, |state| {
            let next = state.position.saturating_add(delta);
            output = next;
            if next == state.position {
                return false;
            }
            state.position = next;
            true
        }) {
            self.notify_debounced();
        }
        output
    }

    pub fn set_length(&self, id: &Uuid, length: u64) {
        if self.update_state(id, |state| {
            if state.length == Some(length) {
                return false;
            }
            state.length = Some(length);
            true
        }) {
            self.notify_debounced();
        }
    }

    pub fn set_position(&self, id: &Uuid, pos: u64) {
        if self.update_state(id, |state| {
            if state.position == pos {
                return false;
            }
            state.position = pos;
            true
        }) {
            self.notify_debounced();
        }
    }

    pub fn remove(&self, id: &Uuid) {
        if self.state.remove_sync(id).is_some() {
            self.notify_immediate();
        }
    }

    fn notify_immediate(&self) {
        self.debounce.lock().dirty = false;
        self.emit_snapshot();
    }

    fn notify_debounced(&self) {
        let handle = match Handle::try_current() {
            Ok(handle) => handle,
            Err(_) => {
                self.notify_immediate();
                return;
            }
        };

        let should_spawn = {
            let mut debounce = self.debounce.lock();
            debounce.dirty = true;
            if debounce.scheduled {
                false
            } else {
                debounce.scheduled = true;
                true
            }
        };

        if should_spawn {
            let progress = self.clone();
            let debounce_window = self.debounce_window;
            handle.spawn(async move {
                time::sleep(debounce_window).await;
                progress.flush_debounced();
            });
        }
    }

    fn flush_debounced(&self) {
        let should_emit = {
            let mut debounce = self.debounce.lock();
            debounce.scheduled = false;
            if debounce.dirty {
                debounce.dirty = false;
                true
            } else {
                false
            }
        };

        if should_emit {
            self.emit_snapshot();
        }
    }

    fn emit_snapshot(&self) {
        let mut states = Vec::new();
        self.state.any_sync(|_k, v| {
            states.push(v.clone());
            false
        });
        self.observer.on_update(states);
    }

    fn new_state(phase: Phase, position: Option<u64>) -> ProgressState {
        ProgressState {
            phase,
            position: position.unwrap_or(0),
            length: None,
        }
    }

    fn update_state(&self, id: &Uuid, mut update: impl FnMut(&mut ProgressState) -> bool) -> bool {
        self.state.update_sync(id, |_k, v| update(v)).unwrap_or(false)
    }
}
