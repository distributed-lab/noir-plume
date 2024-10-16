use bignum::BigNum;
use crate::constants::Fq;

pub fn rev_bytes_32(mut bytes: [u8; 32]) -> [u8; 32] {
    for i in 0..16 {
        let temp = bytes[i];
        bytes[i] = bytes[31-i];
        bytes[31-i] = temp;
    }
    bytes
}

// Binary power algorithm https://cp-algorithms.com/algebra/binary-exp.html
pub fn bin_pow(mut num: Fq, exp: [u8; 32]) -> Fq {
    let mut res = BigNum::one();

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
// secp256k1_prime is 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1 constant
pub fn mod_sqrt(num: Fq) -> Fq {
    let secp256k1_prime_plus_one: Fq = BigNum::from_array([0xfffffffffffffffffffffefffffc30, 0xffffffffffffffffffffffffffffff, 0xffff]);
    let exp: [u8; 32] = (secp256k1_prime_plus_one / BigNum::from_array([4, 0, 0])).to_le_bytes();
    bin_pow(num, exp)
}
