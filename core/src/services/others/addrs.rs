use anyhow::Result;
use std::collections::HashMap;

#[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
pub(in crate::services) fn get() -> Result<HashMap<String, String>> {
    if cfg!(any(target_os = "windows", target_os = "linux", target_os = "macos")) {
        use getifaddrs::{getifaddrs, InterfaceFlags};

        let mut map: HashMap<String, String> = HashMap::new();
        for addr in getifaddrs()? {
            if !addr.flags.contains(InterfaceFlags::RUNNING) || addr.address.ip_addr().is_none() || addr.flags.contains(InterfaceFlags::LOOPBACK) {
                continue;
            }
            let ip_addr = addr.address.ip_addr().unwrap().to_string();
            let name = if cfg!(windows) { addr.description } else { addr.name };
            map.insert(ip_addr, name);
        }
        Ok(map)
    } else {
        use anyhow::anyhow;

        Err(anyhow!("this platform is not supported"))
    }
}
