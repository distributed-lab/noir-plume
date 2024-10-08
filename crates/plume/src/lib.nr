mod constants;
mod utils;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod map_to_curve;
mod iso_map;
mod ec_ops;

use std::bigint::Secpk1Fq;
use std::sha256::sha256_var;

use crate::utils::rev_bytes_32;
use crate::hash_to_curve::hash_to_curve;
use crate::constants::{ZERO, PLUME_MSG_LEN};
use crate::ec_ops::{Point, point_mul, point_add};

/* G in byte format:
   Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
   Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
*/
global G = (Secpk1Fq::from_le_bytes(&[
        152, 23, 248, 22, 91, 129, 242, 89,
        217, 40, 206, 45, 219, 252, 155, 2,
        7, 11, 135, 206, 149, 98, 160, 85,
        172, 187, 220, 249, 126, 102, 190, 121
    ]), Secpk1Fq::from_le_bytes(&[
        184, 212, 16, 251, 143, 208, 71, 156,
        25, 84, 133, 166, 72, 180, 23, 253,
        168, 8, 17, 14, 252, 251, 164, 93,
        101, 196, 163, 38, 119, 218, 58, 72
]));

fn a_div_b_pow_c(a: Point, b: Point, c: [u8; 32]) -> Point {
    let b_pow_c = point_mul(c, b);
    point_add(a, (b_pow_c.0, ZERO - b_pow_c.1))
}

// Apply byte reverse
fn compress_ec_point(pk: Point) -> [u8; 33] {
    let x = pk.0.to_le_bytes();
    let mut compressed = [0 as u8; 33];
    compressed[0] = (pk.1.to_le_bytes()[0] & 1) + 2;

    for i in 0..32 {
        compressed[32-i] = x[i];
    }
    compressed
}

// Return values - r_point, hashed_to_curve_r, hashed_to_curve
fn check_ec_equations<let N: u32>(msg: [u8; N], c: [u8; 32], s: [u8; 32], pk: Point, nullifier: Point) -> (Point, Point, Point) {
    // ECDSAPrivToPub
    let s_point = point_mul(s, G);
    let r_point = a_div_b_pow_c(s_point, pk, c);

    let mut plume_msg = [0; PLUME_MSG_LEN];
    let pk_compress = compress_ec_point(pk);
    for i in 0..N {
        plume_msg[i] = msg[i];
    }
    for i in 0..33 {
        plume_msg[N + i] = pk_compress[i];
    }
    let hashed_to_curve = hash_to_curve(plume_msg);

    let h_pow_s = point_mul(s, hashed_to_curve);
    let hashed_to_curve_r = a_div_b_pow_c(h_pow_s, nullifier, c);
    (r_point, hashed_to_curve_r, hashed_to_curve)
}

fn sha256_6_coordinates(nullifier: Point, gr: Point, hr: Point) -> [u8; 32] {
    let mut compressed = [[0 as u8; 33]; 3];
    compressed[0] = compress_ec_point(nullifier);
    compressed[1] = compress_ec_point(gr);
    compressed[2] = compress_ec_point(hr);

    // Concatenate all compressed bytes
    let mut res = [0 as u8; 99];
    for i in 0..3 {
        for j in 0..33 {
            res[i*33 + j] = compressed[i][j];
        }
    }
    sha256_var(res, res.len() as u64)
}

fn sha256_12_coordinates(pk: Point, h: Point, nullifier: Point, gr: Point, hr: Point) -> [u8; 32] {
    let mut compressed = [[0 as u8; 33]; 6];
    compressed[0] = compress_ec_point(G);
    compressed[1] = compress_ec_point(pk);
    compressed[2] = compress_ec_point(h);
    compressed[3] = compress_ec_point(nullifier);
    compressed[4] = compress_ec_point(gr);
    compressed[5] = compress_ec_point(hr);

    // Concatenate all compressed bytes
    let mut res = [0 as u8; 198];
    for i in 0..6 {
        for j in 0..33 {
            res[i*33 + j] = compressed[i][j];
        }
    }
    sha256_var(res, res.len() as u64)
}

// r*G - r_point
// r*h - hashed_to_curve_r
// sha256(G || Pk || H || N || r*G || r*H)
pub fn plume_v1<let N: u32>(msg: [u8; N], c: [u8; 32], s: [u8; 32], pk: Point, nullifier: Point) {
    let (r_point, hashed_to_curve_r, hashed_to_curve) = check_ec_equations(msg, c, s, pk, nullifier);
    let actual_c = rev_bytes_32(sha256_12_coordinates(pk, hashed_to_curve, nullifier, r_point, hashed_to_curve_r));
    assert(actual_c == c);
}

// https://www.notion.so/mantanetwork/PLUME-Discussion-6f4b7e7cf63e4e33976f6e697bf349ff
pub fn plume_v2<let N: u32>(msg: [u8; N], c2: [u8; 32], s2: [u8; 32], pk: Point, nullifier: Point) {
    let (r_point, hashed_to_curve_r, _) = check_ec_equations(msg, c2, s2, pk, nullifier);
    let actual_c2 = rev_bytes_32(sha256_6_coordinates(nullifier, r_point, hashed_to_curve_r));
    assert(actual_c2 == c2);
}

#[test]
fn test_compress_ec_point() {
    let sk = [
        112, 243, 161, 202, 0, 115, 239, 202, 31, 179, 58, 65, 45, 143, 230, 117, 69, 15, 193, 56, 3, 81, 140, 224, 217, 195, 210, 108, 178, 7, 102, 141
    ];
    let pk = point_mul(sk, G);

    let compressed_pk = compress_ec_point(pk);
    let expected_compressed_pk = [
        2, 251, 188, 92, 195, 140, 107, 160, 47, 132, 242, 112, 141, 138, 178, 59, 234, 158, 144, 47, 203, 20, 59, 174, 56, 127, 68, 229, 111, 95, 233, 172, 226
    ];
    assert(compressed_pk == expected_compressed_pk);
}

#[test]
fn test_nullifier() {
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let H = (Secpk1Fq::from_le_bytes(
            &[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]
        ));

    let nullifier = point_mul(sk, H);
    let expected_nullifier = (Secpk1Fq::from_le_bytes(
            &[
        48, 88, 229, 103, 12, 29, 111, 98, 30, 92, 164, 115, 100, 166, 197, 252, 69, 231, 204, 194, 224, 185, 228, 221, 138, 239, 114, 129, 210, 62, 188, 87
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        115, 203, 158, 229, 127, 8, 214, 145, 168, 143, 163, 126, 230, 58, 159, 159, 96, 17, 225, 136, 33, 221, 110, 228, 58, 243, 88, 141, 72, 65, 47, 106
    ]
        ));
    assert(nullifier == expected_nullifier);
}

#[test]
fn test_r_point() {
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let s = [
        202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230
    ];
    let c = [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ];
    let pk = point_mul(sk, G);
    let s_point = point_mul(s, G);
    let r_point = a_div_b_pow_c(s_point, pk, c);

    let expected_r_point = (Secpk1Fq::from_le_bytes(
            &[
        4, 152, 254, 54, 199, 45, 14, 89, 41, 132, 162, 98, 41, 102, 118, 128, 129, 101, 19, 40, 42, 109, 188, 122, 210, 42, 126, 14, 53, 164, 140, 157
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        161, 197, 112, 118, 106, 129, 84, 144, 155, 45, 71, 18, 81, 228, 235, 188, 198, 170, 195, 217, 53, 200, 35, 70, 133, 78, 253, 138, 11, 195, 8, 255
    ]
        ));
    assert(r_point == expected_r_point);
}

// Failed if the MSG_LEN constant has a value other than 29
/*
#[test]
fn test_hashed_to_curve_msg_with_pk() {
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let pk = point_mul(sk, G);

    // Change MSG_LEN to 29
    let msg = [
        65, 110, 32, 101, 120, 97, 109, 112, 108, 101, 32, 97, 112, 112, 32, 109, 101, 115, 115, 97, 103, 101, 32, 115, 116, 114, 105, 110, 103
    ];

    let mut plume_msg = [0 as u8; PLUME_MSG_LEN];
    let pk_compress = compress_ec_point(pk);
    for i in 0..msg.len() {
        plume_msg[i] = msg[i];
    }
    for i in 0..33 {
        plume_msg[msg.len() + i] = pk_compress[i];
    }
    let hashed_to_curve = hash_to_curve(plume_msg);

    let expected_H = (Secpk1Fq::from_le_bytes(&[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]), Secpk1Fq::from_le_bytes(&[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]));
    assert(hashed_to_curve == expected_H);
}
*/

#[test]
fn test_hashed_to_curve_r() {
    let s = [
        202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230
    ];
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let H = (Secpk1Fq::from_le_bytes(
            &[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]
        ));
    let c = [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ];

    let nullifier = point_mul(sk, H);
    let h_pow_s = point_mul(s, H);
    let hashed_to_curve_r = a_div_b_pow_c(h_pow_s, nullifier, c);

    let expected_hashed_to_curve_r = (Secpk1Fq::from_le_bytes(
            &[
        124, 185, 39, 205, 252, 88, 5, 39, 219, 49, 33, 21, 77, 159, 87, 105, 40, 125, 226, 84, 166, 233, 177, 165, 167, 159, 197, 99, 111, 124, 1, 109
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        237, 86, 172, 119, 183, 144, 226, 164, 161, 245, 202, 198, 211, 68, 63, 62, 248, 101, 138, 168, 128, 143, 74, 86, 140, 129, 153, 92, 251, 67, 108, 88
    ]
        ));
    assert(hashed_to_curve_r == expected_hashed_to_curve_r);
}

// Failed
#[test]
fn test_sha_256_12_coordinates() {
    let hashed_to_curve = (Secpk1Fq::from_le_bytes(
            &[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]
        ));
    let r_point = (Secpk1Fq::from_le_bytes(
            &[
        4, 152, 254, 54, 199, 45, 14, 89, 41, 132, 162, 98, 41, 102, 118, 128, 129, 101, 19, 40, 42, 109, 188, 122, 210, 42, 126, 14, 53, 164, 140, 157
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        161, 197, 112, 118, 106, 129, 84, 144, 155, 45, 71, 18, 81, 228, 235, 188, 198, 170, 195, 217, 53, 200, 35, 70, 133, 78, 253, 138, 11, 195, 8, 255
    ]
        ));
    let hashed_to_curve_r = (Secpk1Fq::from_le_bytes(
            &[
        124, 185, 39, 205, 252, 88, 5, 39, 219, 49, 33, 21, 77, 159, 87, 105, 40, 125, 226, 84, 166, 233, 177, 165, 167, 159, 197, 99, 111, 124, 1, 109
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        237, 86, 172, 119, 183, 144, 226, 164, 161, 245, 202, 198, 211, 68, 63, 62, 248, 101, 138, 168, 128, 143, 74, 86, 140, 129, 153, 92, 251, 67, 108, 88
    ]
        ));

    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];
    let pk = point_mul(sk, G);
    let nullifier = point_mul(sk, hashed_to_curve);

    let actual_c = sha256_12_coordinates(pk, hashed_to_curve, nullifier, r_point, hashed_to_curve_r);

    // method return bytes in reverse order
    let expected_c = rev_bytes_32(
        [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ]
    );
    assert(actual_c == expected_c);
}

// Failed if the MSG_LEN constant has a value other than 29
/*
#[test]
fn test_plume_v1() {
    // "An example app message string", 29 len
    let msg = [
        65, 110, 32, 101, 120, 97, 109, 112, 108, 101, 32, 97, 112, 112, 32, 109, 101, 115, 115, 97, 103, 101, 32, 115, 116, 114, 105, 110, 103
    ];
    let H = (Secpk1Fq::from_le_bytes(&[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]), Secpk1Fq::from_le_bytes(&[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]));
    let s = [
        202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230
    ];
    let c = [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ];
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];

    let pk = point_mul(sk, G);
    let nullifier = point_mul(sk, H);
    plume_v1(msg, c, s, pk, nullifier); // assert inside function
}

#[test]
fn test_plume_v2() {
    let msg = [
        65, 110, 32, 101, 120, 97, 109, 112, 108, 101, 32, 97, 112, 112, 32, 109, 101, 115, 115, 97, 103, 101, 32, 115, 116, 114, 105, 110, 103
    ];
    let H = (Secpk1Fq::from_le_bytes(&[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]), Secpk1Fq::from_le_bytes(&[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]));
    let s2 = [
        107, 19, 152, 128, 203, 119, 17, 15, 146, 90, 8, 17, 214, 75, 82, 146, 122, 148, 178, 115, 26, 123, 121, 0, 34, 248, 82, 100, 187, 143, 142, 82
    ];

    let c2 = [
        150, 235, 52, 52, 54, 59, 107, 138, 158, 11, 171, 131, 167, 211, 91, 71, 75, 231, 149, 12, 114, 112, 74, 244, 212, 16, 80, 112, 23, 183, 191, 61
    ];
    let sk = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];

    let pk = point_mul(sk, G);
    let nullifier = point_mul(sk, H);
    plume_v2(msg, c2, s2, pk, nullifier); // assert inside function
}
*/
