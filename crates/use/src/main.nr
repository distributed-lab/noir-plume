use std::bigint::Secpk1Fq;
use plume::constants::MSG_LEN;
use plume::utils::to_u8_arr;
use plume::{plume_v1, plume_v2};

pub fn main(msg: [u8; MSG_LEN], c: [u8; 32], s: [u8; 32], pk: [[u8; 32]; 2], nullifier: [[u8; 32]; 2]) {
    let pk = (Secpk1Fq::from_le_bytes(to_u8_arr(pk[0])), Secpk1Fq::from_le_bytes(to_u8_arr(pk[1])));
    let nullifier = (
        Secpk1Fq::from_le_bytes(to_u8_arr(nullifier[0])), Secpk1Fq::from_le_bytes(to_u8_arr(nullifier[1]))
    );

    // Choose your plume variant and comment the other

    plume_v1(msg, c, s, pk, nullifier);
    // plume_v2(msg, c, s, pk, nullifier);
}
