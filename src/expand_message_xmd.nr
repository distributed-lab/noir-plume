// Expand Message Xmd
use dep::std::sha256;

use crate::constants::{
    MSG_LEN, PADDING_SIZE,
    DST_PRIME, NUM_PREIMAGE_BYTES
};

pub fn ExpandMessageXmd<N>(msg: [u8; N]) -> [u8; 96] {
    let msg_prime = MsgPrime(msg);

    let b0 = sha256::sha256_var(msg_prime, msg_prime.len());
    let b1 = HashB(1, b0);

    [0; 96]
}

fn MsgPrime<N>(msg: [u8; N]) -> [u8; MSG_LEN + PADDING_SIZE] {
    let z_pad = [0; 64];
    let lib_str = [0, 96];
    let dst_prime = [
        81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116,
        104, 45, 115, 101, 99, 112, 50, 53, 54, 107, 49, 95, 88, 77, 68, 58,
        83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95, 49
    ];

    let mut msg_prime = [0 as u8; MSG_LEN + PADDING_SIZE];

    for i in 0..64 {
        msg_prime[i] = z_pad[i];
    }

    for i in 0..MSG_LEN {
        msg_prime[64 + i] = msg[i];
    }

    for i in 0..2 {
        msg_prime[64 + MSG_LEN + i] = lib_str[i];
    }

    msg_prime[64 + MSG_LEN + 2] = 0;

    // msg_prme = z_pad || msg || lib_str || 0 || dst_prime
    for i in 0..50 {
        msg_prime[64 + MSG_LEN + 2 + 1 + i] = dst_prime[i];
    }

    msg_prime
}

fn print_bits(num: u8) {
    print(num);
    print(" ");
    println((num as Field).to_be_bits(8));
}

fn rev_bits(num: u8) -> u8 {
    let arr = (num as Field).to_le_bits(8);
    let mut res: u64 = 0;

    for i in 0..8 {
        res <<= 1;
        res |= (arr[i] & 1) as u64;
    }
    res as u8
}

fn HashB(b_idx: u8, b0: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);

    let mut res = [0; NUM_PREIMAGE_BYTES];
    for i in 0..32 {
        res[i] = b0[i];
    }
    res[32] = b_idx;

    for i in 0..50 {
        res[32 + 1 + i] = DST_PRIME[i];
    }
    sha256::sha256_var(res, NUM_PREIMAGE_BYTES)
}
