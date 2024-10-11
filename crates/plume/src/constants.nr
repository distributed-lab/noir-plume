use std::bigint::Secpk1Fq;

pub global MSG_LEN = 32;
pub global PLUME_MSG_LEN = MSG_LEN + 33; // Because a point is added, which is compressed to 33 bytes

pub global ZERO = Secpk1Fq::from_le_bytes(&[0]);
pub global ONE = Secpk1Fq::from_le_bytes(&[1]);

// 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1 constant in byte view
pub global SECP256K1_PRIME = Secpk1Fq::from_le_bytes(&[
    47, 252, 255, 255, 254, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255
]);
