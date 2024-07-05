// Expand Message Xmd
use dep::std::sha256;

use crate::MSG_LEN;
use crate::PADDING_SIZE;

pub fn ExpandMessageXmd<N>(msg: [u8; N]) -> [u8; 96] {
    let msg_prime = MsgPrime(msg);

    let b0 = HashMsgPrimeToB0(msg_prime);
    println(b0);

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

fn num_to_bits(num: u8) -> [u8; 8] {
    let mut bits: [u8; 8] = [0; 8];
    let mut n = num;
    for i in 0..8 {
        bits[7 - i] = n & 1;
        n = n >> 1;
    }
    bits
}

fn HashMsgPrimeToB0<T>(msg_prime: [u8; T]) -> [u8; 32] {
    let mut res = msg_prime;

    for i in 0..T {
        let byte = res[i];
        res[i] = 0;

        for j in 0..8 {
            let jbit = (byte >> (7 - j)) & 1;
            res[i] |= jbit << j;
        }
    }
    sha256::sha256_var(res, T)
}
