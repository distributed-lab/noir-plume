use dep::plume::constants::MSG_LEN;
use dep::plume::{plume_v1, plume_v2};

pub fn main(msg: [u8; MSG_LEN], c: [u8; 32], s: [u8; 32], pk: [[u8; 32]; 2], nullifier: [[u8; 32]; 2]) {
    // Choose your plume variant and comment the other

    // plume_v1(msg, c, s, (pk[0], pk[1]), (nullifier[0], nullifier[1]));
    plume_v2(msg, c, s, (pk[0], pk[1]), (nullifier[0], nullifier[1]));
}
