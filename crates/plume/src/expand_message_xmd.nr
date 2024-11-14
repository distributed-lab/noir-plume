/*
    Expand message XMD with SHA-256.
    
    See the link below for more details:

    https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-expand_message_xmd
*/

use std::hash::sha256;

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
    let mut preimage = [0 as u8; 64 + N + 2 + 1 + 50];

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

    sha256(preimage)
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

    sha256(preimage)
}

#[test]
fn test_b0() {
    let msg = [97, 98, 99];

    let actual_b0 = msg_prime(msg);

    let expected_b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87, 48, 157, 28, 243, 255,
        59, 178, 30, 40, 136, 85, 202, 99, 135, 177, 127, 169,
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
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129, 207, 18, 138, 171, 93,
        54, 121, 161, 247, 96, 30, 59, 222, 172, 154, 81, 208,
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
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98, 167, 187, 97, 236,
        186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135, 255,
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
        88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253, 203, 206, 13, 49, 111, 118, 108, 238,
        235, 111, 248, 76, 222, 204, 214, 155, 224, 231, 179, 153, 209,
    ];

    assert(actual_b3 == expected_b3);
}

#[test]
fn tests_expand_message_xmd() {
    let msg = [97, 98, 99];

    let actual = expand_message_xmd(msg);

    let expected = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129, 207, 18, 138, 171, 93,
        54, 121, 161, 247, 96, 30, 59, 222, 172, 154, 81, 208, 197, 77, 255, 208, 84, 39, 78, 219,
        36, 136, 85, 230, 17, 144, 196, 98, 167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174,
        1, 78, 135, 255, 88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253, 203, 206, 13, 49, 111,
        118, 108, 238, 235, 111, 248, 76, 222, 204, 214, 155, 224, 231, 179, 153, 209,
    ];

    assert(actual == expected);
}
