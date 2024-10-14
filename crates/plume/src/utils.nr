use std::bigint::Secpk1Fq;
use crate::constants::{SECP256K1_PRIME};  // ONE too

global ONE = Secpk1Fq::from_le_bytes(&[0]);

// helper method for convenient Secpk1Fq conversion
pub fn to_u8_arr<let N: u32>(smth: [u8; N]) -> [u8] {
    smth
}

pub fn rev_bytes_32(mut bytes: [u8; 32]) -> [u8; 32] {
    for i in 0..16 {
        let temp = bytes[i];
        bytes[i] = bytes[31-i];
        bytes[31-i] = temp;
    }
    bytes
}

pub fn rev_bytes_48(mut bytes: [u8; 48]) -> [u8; 48] {
    for i in 0..24 {
        let temp = bytes[i];
        bytes[i] = bytes[47-i];
        bytes[47-i] = temp;
    }
    bytes
}

// Binary power algorithm https://cp-algorithms.com/algebra/binary-exp.html
pub fn bin_pow(mut num: Secpk1Fq, pow: Secpk1Fq) -> Secpk1Fq {
    let mut res = ONE;
    let exp = pow.to_le_bytes();

    for i in 0..exp.len() {
        for j in 0..8 {
            if exp[i] & (1 << j) != 0 {
                res = res * num;
            }
            num = num * num;
        }
    }
    res
}

// We use the formula R = num^((p+1)/4), since SECP256K1_PRIME % 4 == 3
// https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
pub fn mod_sqrt(num: Secpk1Fq) -> Secpk1Fq {
    let p_plus_one = SECP256K1_PRIME + ONE;
    bin_pow(num, p_plus_one / Secpk1Fq::from_le_bytes(&[4]))
}
