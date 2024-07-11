use crate::constants::{Z, SECP256K1_PRIME};
use crate::biguint::BigUint;

// For now I don't know the output format
pub fn MapToCurve(u: [u8; 32]) -> Field {
    // Step 1
    let big_u = BigUint::from_bytes_32(u);
    let big_z = BigUint::from_bytes_32(Z);
    let big_P = BigUint::from_bytes(SECP256K1_PRIME);
    //let mut (_quo, rem) = big_z.mul(big_u).mul(big_u).div(big_P);

    // Step 2
    0
}
