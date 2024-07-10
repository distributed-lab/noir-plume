// Expand Message Xmd
use dep::std::sha256::sha256_var;
use crate::constants::{MSG_LEN, PADDING_SIZE, DST_PRIME, NUM_PREIMAGE_BYTES};

pub fn ExpandMessageXmd<N>(msg: [u8; N]) -> [u8; 96] {
    let msg_prime = MsgPrime(msg);

    let b0 = sha256_var(msg_prime, msg_prime.len());
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

fn MsgPrime<N>(msg: [u8; N]) -> [u8; MSG_LEN + PADDING_SIZE] {
    let z_pad = [0; 64];
    let lib_str = [0, 96];
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
        msg_prime[64 + MSG_LEN + 2 + 1 + i] = DST_PRIME[i];
    }

    msg_prime
}

fn HashB(b_idx: u8, b: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);

    let mut res = [0; NUM_PREIMAGE_BYTES];
    for i in 0..32 {
        res[i] = b[i];
    }
    res[32] = b_idx;

    for i in 0..50 {
        res[32 + 1 + i] = DST_PRIME[i];
    }
    sha256_var(res, NUM_PREIMAGE_BYTES)
}

fn HashBi(b_idx: u8, b0: [u8; 32], b1: [u8; 32]) -> [u8; 32] {
    assert(b_idx < 8);

    let mut res = [0 as u8; 32];
    for i in 0..32 {
        res[i] = b0[i] ^ b1[i];
    }
    HashB(b_idx, res)
}

// Test methods
// Maybe need to delete later
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
