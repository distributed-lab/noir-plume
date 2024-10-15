use bignum::BigNum;
use bignum::fields::secp256k1Fq::Secp256k1_Fq_Params;
pub type Fq = BigNum<3, Secp256k1_Fq_Params>;

pub global MSG_LEN: u32 = 32;
pub global PLUME_MSG_LEN: u32 = MSG_LEN + 33; // Because a point is added, which is compressed to 33 bytes

pub global ZERO = BigNum::from_array([0, 0, 0]);
