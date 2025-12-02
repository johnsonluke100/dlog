use blake3::Hasher;
use std::env;
use std::time::{SystemTime, UNIX_EPOCH};

const ASSETS: &[&str] = &["XAUT", "BTC", "DOGE"];
const SLOTS: usize = 256;

fn main() {
    let passphrase = env::var("OMEGA_BANK_PASSPHRASE").ok();
    let salt = env::var("OMEGA_BANK_SALT").unwrap_or_else(|_| "omega-bank".to_string());
    let key_material = format!("{}|{}", passphrase.as_deref().unwrap_or(""), salt.as_str());
    let key_bytes: [u8; 32] = *blake3::hash(key_material.as_bytes()).as_bytes();

    let epoch = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    println!(
        ";omega_bank;plan;epoch;{};slots;{};passphrase_set;{};",
        epoch,
        SLOTS,
        passphrase.is_some() as u8
    );
    println!("# asset,index,id_hex16,mode");

    for &asset in ASSETS {
        for idx in 0..SLOTS {
            let id = derive_id(asset, idx as u16, &key_bytes);
            let mode = if passphrase.is_some() {
                "secure"
            } else {
                "stub"
            };
            println!("{asset},{idx:03},{id},{mode}");
        }
    }
}

fn derive_id(asset: &str, index: u16, key: &[u8; 32]) -> String {
    let mut hasher = Hasher::new_keyed(key);
    hasher.update(asset.as_bytes());
    hasher.update(&index.to_be_bytes());
    let digest = hasher.finalize();
    to_hex(&digest.as_bytes()[..16]) // 128-bit id
}

fn to_hex(bytes: &[u8]) -> String {
    const HEX: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(bytes.len() * 2);
    for &b in bytes {
        out.push(HEX[(b >> 4) as usize] as char);
        out.push(HEX[(b & 0x0f) as usize] as char);
    }
    out
}
