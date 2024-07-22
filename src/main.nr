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

// For testing
use crate::ec_ops::PointMul;
use crate::plume::{get_gx, get_gy};

pub fn main(
    msg: [u8; constants::MSG_LEN],
    c: [u8; 32],
    s: [u8; 32],
    pk: [[u8; 32]; 2],
    nullifier: [[u8; 32]; 2]
) {
    /*
    let expected_c = plume::plume_v1(msg, c, s, (pk[0], pk[1]), (nullifier[0], nullifier[1]));
    assert(expected_c == c);
    */

    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let H = ([
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ], [
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]);

    let nullifier = PointMul(sk, H);
    let expected_nullifier = ([
        48, 88, 229, 103, 12, 29, 111, 98, 30, 92, 164, 115, 100, 166, 197, 252, 69, 231, 204, 194, 224, 185, 228, 221, 138, 239, 114, 129, 210, 62, 188, 87
    ], [
        115, 203, 158, 229, 127, 8, 214, 145, 168, 143, 163, 126, 230, 58, 159, 159, 96, 17, 225, 136, 33, 221, 110, 228, 58, 243, 88, 141, 72, 65, 47, 106
    ]);

    println(nullifier);
}
