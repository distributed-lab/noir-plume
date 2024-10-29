use bignum::BigNum;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::BigCurve;
use noir_bigcurve::scalar_field::ScalarField;

use plume::plume_v1;

global MSG_LEN: u32 = 32;

pub fn main(msg: [u8; MSG_LEN], c: [u8; 32], s: [u8; 32], pk: [[u8; 32]; 2], nullifier: [[u8; 32]; 2]) {
    let actual_c = plume_v1(
        msg,
        as_scalar(c),
        as_scalar(s),
        as_point(pk),
        as_point(nullifier)
    );

    assert(c == actual_c);
}

fn as_scalar(bytes: [u8; 32]) -> Secp256k1Scalar {
    let scalar: Secp256k1Fr = BigNum::from_be_bytes(bytes);
    ScalarField::from_bignum(scalar)
}

fn as_point(bytes: [[u8; 32]; 2]) -> Secp256k1 {
    BigCurve { x: BigNum::from_be_bytes(bytes[0]), y: BigNum::from_be_bytes(bytes[1]), is_infinity: false }
}
