use anyhow::Result;
use std::collections::HashMap;

#[cfg(any(target_os = "linux", target_os = "macos"))]
pub(in crate::services) fn get() -> Result<HashMap<String, String>> {
    use getifaddrs::{getifaddrs, InterfaceFlags};

    let mut map: HashMap<String, String> = HashMap::new();
    for addr in getifaddrs()? {
        if !addr.flags.contains(InterfaceFlags::RUNNING) || addr.address.ip_addr().is_none() || addr.flags.contains(InterfaceFlags::LOOPBACK) {
            continue;
        }
        let ip_addr = addr.address.ip_addr().unwrap().to_string();
        map.insert(ip_addr, addr.name);
    }
    Ok(map)
}

#[cfg(target_os = "windows")]
pub(in crate::services) fn get() -> Result<HashMap<String, String>> {
    use getifaddrs::{getifaddrs, InterfaceFlags};

    let mut map: HashMap<String, String> = HashMap::new();
    for addr in getifaddrs()? {
        if !addr.flags.contains(InterfaceFlags::RUNNING) || addr.address.ip_addr().is_none() || addr.flags.contains(InterfaceFlags::LOOPBACK) {
            continue;
        }
        let ip_addr = addr.address.ip_addr().unwrap().to_string();
        map.insert(ip_addr, addr.description);
    }
    Ok(map)
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub(in crate::services) fn get() -> Result<HashMap<String, String>> {
    use tracing::warn;

    warn!("this platform is not supported");
    Ok(HashMap::new())
}
