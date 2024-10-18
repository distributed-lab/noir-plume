use bignum::BigNum;
use plume::constants::MSG_LEN;
use plume::{plume_v1, plume_v2};

pub fn main(msg: [u8; MSG_LEN], c: [u8; 32], s: [u8; 32], pk: [[u8; 32]; 2], nullifier: [[u8; 32]; 2]) {
    let pk = (BigNum::from_be_bytes(pk[0]), BigNum::from_be_bytes(pk[1]));
    let nullifier = (BigNum::from_be_bytes(nullifier[0]), BigNum::from_be_bytes(nullifier[1]));
    // Choose your plume variant and comment the other

    // plume_v1(msg, c, s, pk, nullifier);
    plume_v2(msg, c, s, pk, nullifier);
}
