mod constants;
mod biguint;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod map_to_curve;
mod iso_map;

// For tests
use crate::biguint::BigUint;
use crate::map_to_curve::XY2Selector;
use dep::std::bigint::Secpk1Fq;

pub fn main(msg: [u8; constants::MSG_LEN]) {
    //let _p = hash_to_curve::hash_to_curve(msg);
    // println(p.0);
    // println(p.1);

    /*
    let u0_bytes = [
        97, 43, 138, 176, 151, 243, 115, 72,
        138, 225, 103, 71, 84, 31, 73, 62,
        244, 209, 206, 148, 223, 59, 30, 96,
        247, 161, 121, 54, 93, 171, 138, 18
    ];

    let (x, y) = map_to_curve::MapToCurve(u0_bytes);
    let expected_x = [
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ];
    let expected_y = [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ];

    println("\nres");
    println(x);
    println(y);
    */
}
