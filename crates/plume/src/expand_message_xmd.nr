/*
    Expand message XMD with SHA-256.
    
    See the link below for more details:

    https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-expand_message_xmd
*/

use crate::utils::to_field;
use std::hash::poseidon2::Poseidon2::hash;

comptime global DST_PRIME: [u8; 50] = [
    81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116, 104, 45, 115, 101, 99,
    112, 50, 53, 54, 107, 49, 95, 88, 77, 68, 58, 83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85,
    95, 82, 79, 95, 49,
];

pub fn expand_message_xmd<let N: u32>(msg: [u8; N]) -> [u8; 96] {
    let b0 = msg_prime(msg);
    let b1 = hash_b(1, b0);
    let b2 = hash_bi(2, b0, b1);
    let b3 = hash_bi(3, b0, b2);

    let mut out = [0 as u8; 96];
    for i in 0..32 {
        out[i] = b1[i];
    }
    for i in 0..32 {
        out[32 + i] = b2[i];
    }
    for i in 0..32 {
        out[64 + i] = b3[i];
    }

    out
}

fn msg_prime<let N: u32>(msg: [u8; N]) -> [u8; 32] {
    let mut preimage = [0; 64 + N + 2 + 1 + 50];

    for i in 0..N {
        preimage[64 + i] = msg[i];
    }

    let lib_str = [0, 96];
    for i in 0..lib_str.len() {
        preimage[64 + N + i] = lib_str[i];
    }

    preimage[64 + N + 2] = 0;

    for i in 0..50 {
        preimage[64 + N + 2 + 1 + i] = DST_PRIME[i];
    }

    hash([to_field(preimage)], preimage.len()).to_le_bytes()
}

fn hash_bi(b_idx: u8, b0: [u8; 32], b1: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);

    let mut res = [0 as u8; 32];
    for i in 0..32 {
        res[i] = b0[i] ^ b1[i];
    }

    hash_b(b_idx, res)
}

fn hash_b(b_idx: u8, b: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);
    let mut preimage = [0; 32 + 1 + 50];

    for i in 0..32 {
        preimage[i] = b[i];
    }

    preimage[32] = b_idx;

    for i in 0..50 {
        preimage[32 + 1 + i] = DST_PRIME[i];
    }

    hash([to_field(preimage)], 32 + 1 + 50).to_le_bytes()
}

#[test]
fn test_b0() {
    let msg = [97, 98, 99];

    let actual_b0 = msg_prime(msg);

    let expected_b0 = [
        244, 228, 186, 229, 167, 240, 72, 35, 72, 201, 30, 135, 116, 200, 92, 252, 236, 82, 101,
        168, 168, 57, 38, 207, 131, 64, 78, 122, 157, 1, 18, 24,
    ];

    assert(actual_b0 == expected_b0);
}

#[test]
fn test_b1() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87, 48, 157, 28, 243, 255,
        59, 178, 30, 40, 136, 85, 202, 99, 135, 177, 127, 169,
    ];

    let actual_b1 = hash_b(1, b0);

    let expected_b1 = [
        89, 48, 72, 196, 27, 115, 11, 241, 49, 124, 218, 4, 173, 23, 162, 23, 197, 100, 206, 65,
        138, 54, 118, 91, 227, 59, 205, 92, 169, 126, 183, 19,
    ];

    assert(actual_b1 == expected_b1);
}

#[test]
fn test_b2() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87, 48, 157, 28, 243, 255,
        59, 178, 30, 40, 136, 85, 202, 99, 135, 177, 127, 169,
    ];
    let b1 = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129, 207, 18, 138, 171, 93,
        54, 121, 161, 247, 96, 30, 59, 222, 172, 154, 81, 208,
    ];

    let actual_b2 = hash_bi(2, b0, b1);

    let expected_b2 = [
        133, 159, 203, 25, 88, 52, 139, 16, 136, 49, 25, 62, 168, 65, 240, 66, 165, 74, 249, 195,
        42, 193, 228, 164, 33, 237, 94, 227, 186, 125, 68, 11,
    ];

    assert(actual_b2 == expected_b2);
}

#[test]
fn test_b3() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87, 48, 157, 28, 243, 255,
        59, 178, 30, 40, 136, 85, 202, 99, 135, 177, 127, 169,
    ];
    let b2 = [
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98, 167, 187, 97, 236,
        186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135, 255,
    ];

    let actual_b3 = hash_bi(3, b0, b2);

    let expected_b3 = [
        145, 148, 34, 154, 234, 103, 0, 76, 186, 111, 76, 140, 236, 216, 242, 103, 15, 219, 30, 210,
        242, 150, 26, 87, 138, 33, 62, 148, 77, 121, 194, 43,
    ];

    assert(actual_b3 == expected_b3);
}

#[test]
fn tests_expand_message_xmd() {
    let msg = [97, 98, 99];

    let actual = expand_message_xmd(msg);

    let expected = [
        103, 141, 171, 70, 97, 109, 246, 57, 155, 74, 200, 143, 190, 146, 248, 216, 99, 128, 203,
        147, 154, 97, 9, 16, 20, 126, 227, 220, 17, 82, 92, 10, 135, 163, 156, 89, 40, 209, 79, 185,
        200, 163, 90, 58, 204, 178, 133, 126, 51, 174, 97, 122, 161, 186, 14, 10, 117, 173, 249,
        129, 22, 15, 216, 39, 47, 75, 79, 183, 145, 85, 2, 79, 86, 203, 240, 113, 245, 201, 57, 46,
        215, 177, 234, 222, 89, 150, 143, 80, 214, 21, 193, 27, 60, 38, 84, 33,
    ];

    assert(actual == expected);
}
