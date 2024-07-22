mod constants;
mod biguint;
mod utils;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod map_to_curve;
mod iso_map;
mod ec_ops;
mod plume;

pub fn main(
    msg: [u8; constants::MSG_LEN],
    c: [u8; 32],
    s: [u8; 32],
    pk: [[u8; 32]; 2],
    nullifier: [[u8; 32]; 2]
) {
    let expected_c = plume::plume_v1(msg, c, s, (pk[0], pk[1]), (nullifier[0], nullifier[1]));
    assert(expected_c == c);
}
