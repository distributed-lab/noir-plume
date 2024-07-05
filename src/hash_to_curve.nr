// Hash to curve
type Point = (Field, Field);

use dep::std::sha256;

pub fn hash_to_curve<N>(msg: [u8; N]) -> Point {

    // here input some unknown number arrays

    // Step 1: u = hash_to_field(msg)
    let h2f = hash_to_field(msg);
    (0, 0)
}


// Hash To Field
fn hash_to_field<N>(msg: [u8; N]) -> Field {
    let expand_message_xmd = ExpandMessageXmd(msg);
    0
}


// Expand Message Xmd
fn calc_msg_prime_output_length(msg_length: u64) -> u64 {
    msg_length + 64 + 2 + 50 + 1
}

fn ExpandMessageXmd<N>(msg: [u8; N]) -> [Field; 96] {
    let msg_prime = MsgPrime(msg);

    let b0 = HashMsgPrimeToB0(msg, msg_prime);
    /*
    let b1 = HashB(1);
    let b2 = HashBi(2);
    let b3 = HashBi(3);
    */

    [0; 96]
}

fn MsgPrime<N>(msg: [u8; N]) -> Vec<u8> {
    let z_pad = [0; 64];
    let lib_str = [0, 96];
    let dst_prime = [
        81, 85, 85, 88, 45, 86, 48, 49, 45, 67, 83, 48, 50, 45, 119, 105, 116,
        104, 45, 115, 101, 99, 112, 50, 53, 54, 107, 49, 95, 88, 77, 68, 58,
        83, 72, 65, 45, 50, 53, 54, 95, 83, 83, 87, 85, 95, 82, 79, 95, 49
    ];

    let mut msg_prime = Vec::new();

    for i in 0..z_pad.len() {
        msg_prime.push(z_pad[i])
    }

    for i in 0..N {
        msg_prime.push(msg[i]);
    }

    for i in 0..lib_str.len() {
        msg_prime.push(lib_str[i]);
    }

    msg_prime.push(0);

    for i in 0..dst_prime.len() {
        msg_prime.push(dst_prime[i])
    }

    msg_prime
}

fn HashMsgPrimeToB0<N, T>(msg: [u8; N], msg_prime: Vec<u8>) -> [u8; 256] {

    //let arr = [1; msg_prime_len]
    let bytes = [163, 117, 178, 149];
    //let hasher = sha256::sha256_var(bytes, 4);


    [0; 256]
}
