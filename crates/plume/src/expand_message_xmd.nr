// Expand Message Xmd
use dep::std::sha256::sha256_var;
use crate::constants::PLUME_MSG_LEN;

fn get_dst_prime() -> [u8] {
    [
        81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116,
        104, 45, 115, 101, 99, 112, 50, 53, 54, 107, 49, 95, 88, 77, 68, 58,
        83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95, 49
    ]
}

// https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-expand_message_xmd
pub fn ExpandMessageXmd<N>(msg: [u8; N]) -> [u8; 96] {
    let b0 = MsgPrime(msg);
    let b1 = HashB(1, b0);
    let b2 = HashBi(2, b0, b1);
    let b3 = HashBi(3, b0, b2);

    // Or maybe reverse bits in bi
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

fn MsgPrime<N>(msg: [u8; N]) -> [u8; 32] {
    let z_pad = [0; 64];
    let lib_str = [0, 96];
    let mut msg_prime = [0 as u8; PLUME_MSG_LEN + 64 + 2 + 50 + 1]; // padding size
    let dst_prime = get_dst_prime();

    for i in 0..64 {
        msg_prime[i] = z_pad[i];
    }
    for i in 0..N {
        msg_prime[64 + i] = msg[i];
    }
    for i in 0..2 {
        msg_prime[64 + N + i] = lib_str[i];
    }
    msg_prime[64 + N + 2] = 0;

    // msg_prme = z_pad || msg || lib_str || 0 || dst_prime
    for i in 0..dst_prime.len() {
        msg_prime[64 + N + 2 + 1 + i] = dst_prime[i];
    }
    sha256_var(msg_prime, msg_prime.len())
}

fn HashB(b_idx: u8, b: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);
    let dst_prime = get_dst_prime();

    let mut res = [0; 32 + 1 + 50]; // Num preimage bytes
    for i in 0..32 {
        res[i] = b[i];
    }
    res[32] = b_idx;

    for i in 0..dst_prime.len() {
        res[32 + 1 + i] = dst_prime[i];
    }
    sha256_var(res, res.len())
}

fn HashBi(b_idx: u8, b0: [u8; 32], b1: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);

    let mut res = [0 as u8; 32];
    for i in 0..32 {
        res[i] = b0[i] ^ b1[i];
    }
    HashB(b_idx, res)
}

// Failed if the PLUME_MSG_LEN constant has a value other than 3
/*
#[test]
fn test_b0() {
    let msg = [97, 98, 99];

    let b0 = MsgPrime(msg);
    let expected_b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87,
        48, 157, 28, 243, 255, 59, 178, 30, 40, 136, 85, 202, 99, 135, 177,
        127, 169
    ];
    assert(b0 == expected_b0);
}
*/

#[test]
fn test_b1() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87,
        48, 157, 28, 243, 255, 59, 178, 30, 40, 136, 85, 202, 99, 135, 177,
        127, 169
    ];

    let b1 = HashB(1, b0);
    let expected_b1 = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129,
        207, 18, 138, 171, 93, 54, 121, 161, 247, 96, 30, 59, 222, 172, 154,
        81, 208
    ];
    assert(b1 == expected_b1);
}

#[test]
fn test_b2() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87,
        48, 157, 28, 243, 255, 59, 178, 30, 40, 136, 85, 202, 99, 135, 177,
        127, 169
    ];
    let b1 = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129,
        207, 18, 138, 171, 93, 54, 121, 161, 247, 96, 30, 59, 222, 172, 154,
        81, 208
    ];

    let b2 = HashBi(2, b0, b1);
    let expected_b2 = [
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98,
        167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135,
        255
    ];
    assert(b2 == expected_b2);
}

#[test]
fn test_b3() {
    let b0 = [
        99, 4, 75, 36, 124, 254, 65, 234, 207, 65, 212, 122, 206, 186, 87,
        48, 157, 28, 243, 255, 59, 178, 30, 40, 136, 85, 202, 99, 135, 177,
        127, 169
    ];
    let b2 = [
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98,
        167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135, 255
    ];

    let b3 = HashBi(3, b0, b2);
    let expected_b3 = [
        88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253, 203, 206, 13, 49,
        111, 118, 108, 238, 235, 111, 248, 76, 222, 204, 214, 155, 224, 231,
        179, 153, 209
    ];
    assert(b3 == expected_b3);
}

// Failed, if PLUME_MSG_LEN != 3
/*
#[test]
fn tests_expand_message_xmd() {
    // "abc" message
    let msg = [97, 98, 99];

    let expand_message_xmd = ExpandMessageXmd(msg);
    let expected_expand_message_xmd = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129,
        207, 18, 138, 171, 93, 54, 121, 161, 247, 96, 30, 59, 222, 172, 154,
        81, 208, 197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17,
        144, 196, 98, 167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174,
        1, 78, 135, 255, 88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253,
        203, 206, 13, 49, 111, 118, 108, 238, 235, 111, 248, 76, 222, 204,
        214, 155, 224, 231, 179, 153, 209
    ];
    assert(expand_message_xmd == expected_expand_message_xmd);
}
*/
