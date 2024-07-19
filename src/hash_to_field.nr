use dep::std::bigint::Secpk1Fq;
use crate::expand_message_xmd::ExpandMessageXmd;
use crate::constants::SECP256K1_PRIME;
use crate::biguint::BigUint;
use crate::ec_ops::Point;


// https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-hashing-to-a-finite-field
pub fn hash_to_field<N>(msg: [u8; N]) -> Point {
    let expand_message_xmd = ExpandMessageXmd(msg);

    let mut u0_bytes_to_registers = [0 as u8; 48];
    let mut u1_bytes_to_registers = [0 as u8; 48];

    for i in 0..48 {
        u0_bytes_to_registers[i] = expand_message_xmd[i];
        u1_bytes_to_registers[i] = expand_message_xmd[48 + i];
    }

    let u0_bytes_to_registers = BytesToRegisters(u0_bytes_to_registers);
    let u1_bytes_to_registers = BytesToRegisters(u1_bytes_to_registers);
    (u0_bytes_to_registers, u1_bytes_to_registers)
}

fn BytesToRegisters(ui: [u8; 48]) -> [u8; 32] {
    let a = BigUint::from_bytes(get_be_bytes(ui));
    let rem = a.div(BigUint::from_bytes_32(SECP256K1_PRIME)).1;
    rem.to_bytes_32()
}

fn get_be_bytes(ui: [u8; 48]) -> [u8] {
    let mut res = ui;
    for i in 0..24 {
        let temp = res[i];
        res[i] = res[47-i];
        res[47-i] = temp;
    }
    res
}


#[test]
fn test_u0_bytes_to_registers() {
    let u0_bytes = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129, 207,
        18, 138, 171, 93, 54, 121, 161, 247, 96, 30, 59, 222, 172, 154, 81, 208,
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98
    ];

    let u0_bytes_to_registers = BytesToRegisters(u0_bytes);
    let expected_u0_bytes_to_registers = [
        97, 43, 138, 176, 151, 243, 115, 72,
        138, 225, 103, 71, 84, 31, 73, 62,
        244, 209, 206, 148, 223, 59, 30, 96,
        247, 161, 121, 54, 93, 171, 138, 18
    ];
    assert(u0_bytes_to_registers == expected_u0_bytes_to_registers);
}

#[test]
fn test_u1_bytes_to_registers() {
    let u1_bytes = [
        167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135, 255,
        88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253, 203, 206, 13, 49, 111,
        118, 108, 238, 235, 111, 248, 76, 222, 204, 214, 155, 224, 231, 179, 153, 209
    ];

    let u1_bytes_to_registers = BytesToRegisters(u1_bytes);
    let expected_u1_bytes_to_registers = [
        0, 158, 104, 228, 242, 160, 170, 77,
        4, 139, 81, 3, 106, 231, 27, 83,
        220, 149, 200, 117, 204, 253, 208, 19,
        168, 149, 181, 163, 93, 182, 151, 88
    ];
    assert(u1_bytes_to_registers == expected_u1_bytes_to_registers);
}
