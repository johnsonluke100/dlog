use blake3::Hasher as Blake3Hasher;
use num_bigint::BigUint;
use sha2::{Digest, Sha512};
use spec::LabelId;
use std::collections::HashMap;

/// Compute the Ω master root string for a given height + balance map.
pub fn master_root_for(height: u64, balances: &HashMap<LabelId, f64>) -> String {
    let payload = serde_json::json!({
        "height": height,
        "balances": balances,
    });
    let bytes = serde_json::to_vec(&payload).unwrap_or_default();
    let digest = shaless_hash(&bytes);
    infinity_base(&digest)
}

fn shaless_hash(data: &[u8]) -> [u8; 128] {
    let mut sha = Sha512::new();
    sha.update(data);
    let sha_out = sha.finalize();

    let mut blake_out = [0u8; 64];
    Blake3Hasher::new()
        .update(data)
        .finalize_xof()
        .fill(&mut blake_out);

    let mut combined = [0u8; 128];
    combined[..64].copy_from_slice(&sha_out);
    combined[64..].copy_from_slice(&blake_out);
    combined
}

fn infinity_base(hash: &[u8]) -> String {
    let big = BigUint::from_bytes_be(hash);
    let base8 = big.to_str_radix(8);
    format!(";∞;sha-less;{base8};")
}
