use anyhow::{anyhow, Result};
use rxing::{helpers::detect_in_buffer, BarcodeFormat};

pub(in crate::services) fn reader(image: Vec<u8>) -> Result<Vec<u8>> {
    match detect_in_buffer(&image, Some(BarcodeFormat::QR_CODE)) {
        Ok(res) => {
            return Ok(res.getRawBytes().to_vec());
        }
        Err(e) => Err(anyhow!("{}", e)),
    }
}
