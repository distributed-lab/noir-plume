use bignum::BigNum;
use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use noir_bigcurve::BigCurve;
use noir_bigcurve::scalar_field::ScalarField;

use plume::{plume_v1, plume_v2};

global MSG_LEN: u32 = 32;

pub fn main(msg: [u8; MSG_LEN], c: [u8; 32], s: [u8; 32], pk: [[u8; 32]; 2], nullifier: [[u8; 32]; 2]) {
    let s: Secp256k1Fr = BigNum::from_be_bytes(s);
    let s: Secp256k1Scalar = ScalarField::from_bignum(s);

    let pk: Secp256k1 = BigCurve {
        x: BigNum::from_be_bytes(pk[0]),
        y: BigNum::from_be_bytes(pk[1]),
        is_infinity: false // we never pass inf in Prover.toml
    };

    let nullifier: Secp256k1 = BigCurve {
        x: BigNum::from_be_bytes(nullifier[0]),
        y: BigNum::from_be_bytes(nullifier[1]),
        is_infinity: false // we never pass inf in Prover.toml
    };

    // Choose your plume variant and comment the other

    // plume_v1(msg, c, s, pk, nullifier);
    plume_v2(msg, c, s, pk, nullifier);
}
