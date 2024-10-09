use bignum::BigNum;
use bignum::fields::secp256k1Fq::Secp256k1_Fq_Params;
use bignum::runtime_bignum;

type Secp256k1 = BigNum<3, Secp256k1_Fq_Params>;

pub fn test_new_point_mul() {
    let stub: Secp256k1 = BigNum::one();
}