use dep::std::bigint::Secpk1Fq;
use crate::constants::SECP256K1_PRIME;

// helper methods for convenient Secpk1Fq conversion
pub fn to_u8_arr(smth: [u8; 32]) -> [u8] {
    smth
}

pub fn to_u8_32(smth: [u8]) -> [u8; 32] {
    let mut res = [0 as u8; 32];
    for i in 0..smth.len() {
        res[i] = smth[i];
    }
    res
}

// Binary power algorithm https://cp-algorithms.com/algebra/binary-exp.html
pub fn bin_pow(mut num: Secpk1Fq, pow: Secpk1Fq) -> Secpk1Fq {
    let mut res = Secpk1Fq::from_le_bytes(&[1]);
    let exp = pow.to_le_bytes();

    for i in 0..exp.len() {
        let byte = (exp[i] as Field).to_le_bits(8);

        for j in 0..8 {
            if byte[j] == 1 {
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
    let p_plus_one = Secpk1Fq::from_le_bytes(to_u8_arr(SECP256K1_PRIME)) + Secpk1Fq::from_le_bytes(&[1]);
    bin_pow(num, p_plus_one / Secpk1Fq::from_le_bytes(&[4]))
}

// p is SECP256K1_PRIME, then
// mod_mul_inv(a, p) = a ^ (p-2) % p
pub fn mod_mul_inv(mut num: Secpk1Fq) -> Secpk1Fq {
    bin_pow(
        num,
        Secpk1Fq::from_le_bytes(to_u8_arr(SECP256K1_PRIME)) - Secpk1Fq::from_le_bytes(&[2])
    )
}
