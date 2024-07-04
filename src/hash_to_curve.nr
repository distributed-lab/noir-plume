type Point = (Field, Field);

fn calc_msg_prime_output_length(msg_length: u64) -> u64 {
    msg_length + 64 + 2 + 50 + 1
}


pub fn hash_to_curve(msg: str) -> Point {

    // here input some unknown arrays of number

    // Step 1: u = hash_to_field(msg)
    let h2f = hash_to_field(msg);
    (0, 0)
}

fn hash_to_field(msg: str) -> Field {
    let msg_prime = MsgPrime(msg);
    println(msg);
    0
}

fn MsgPrime(msg: str) -> Vec<u8> {
    let msg = msg.as_bytes();
    let msg_len = msg.len();
    let output_len = calc_msg_prime_output_length(msg_len);

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

    for i in 0..msg_len {
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