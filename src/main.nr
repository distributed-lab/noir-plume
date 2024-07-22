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
// use crate::ec_ops::PointMul;
// use crate::plume::{get_gx, get_gy};

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

    let msg = [97, 98, 99];
    let H = ([
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ], [
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]);
    let s = [
        202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230
    ];
    let actual_c = [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ];
    let sk = [
        81, 155, 66, 61, 113, 95, 139, 88, 31, 79, 168, 238, 89, 244, 119, 26, 91, 68, 200, 19, 11, 78, 62, 172, 202, 84, 165, 109, 218, 114, 180, 100
    ];
    
    let pk = PointMul(sk, (get_gx(), get_gy()));
    let nullifier = PointMul(sk, H);

    let actual_c = plume::plume_v1(msg, actual_c, s, pk, nullifier);
    println(actual_c);
}
