use bignum::BigNum;
use crate::expand_message_xmd::expand_message_xmd;
use crate::constants::Fq;
use crate::ec_ops::Point;

fn bytes_to_registers(ui: [u8; 48]) -> Fq {
    let shift = BigNum::from_array([0, 0x100, 0]);
    let mut small = [0 as u8; 32];
    let mut big = [0 as u8; 32];

    for i in 0..16 {
        small[i+16] = ui[i+32];
    }
    for i in 0..32 {
        big[i] = ui[i];
    }
    let res = BigNum::from_be_bytes(big);
    res * shift + BigNum::from_be_bytes(small)
}

// https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-hashing-to-a-finite-field
pub fn hash_to_field<let N: u32>(msg: [u8; N]) -> Point {
    let expand_message_xmd = expand_message_xmd(msg);

    let mut u0_bytes_to_registers = [0 as u8; 48];
    let mut u1_bytes_to_registers = [0 as u8; 48];

    for i in 0..48 {
        u0_bytes_to_registers[i] = expand_message_xmd[i];
        u1_bytes_to_registers[i] = expand_message_xmd[48 + i];
    }

    let u0_bytes_to_registers = bytes_to_registers(u0_bytes_to_registers);
    let u1_bytes_to_registers = bytes_to_registers(u1_bytes_to_registers);
    (u0_bytes_to_registers, u1_bytes_to_registers)
}

#[test]
fn test_u0_bytes_to_registers() {
    let u0_bytes = [
        232, 52, 124, 173, 72, 171, 78, 49, 157, 123, 39, 85, 32, 234, 129, 207,
        18, 138, 171, 93, 54, 121, 161, 247, 96, 30, 59, 222, 172, 154, 81, 208,
        197, 77, 255, 208, 84, 39, 78, 219, 36, 136, 85, 230, 17, 144, 196, 98
    ];

    let u0_bytes_to_registers = bytes_to_registers(u0_bytes);
    let expected_u0_bytes_to_registers = BigNum::from_array([0x491f544767e18a4873f397b08a2b61, 0xab5d3679a1f7601e3bdf94ced1f43e, 0x128a]);
    assert(u0_bytes_to_registers == expected_u0_bytes_to_registers);
}

#[test]
fn test_u1_bytes_to_registers() {
    let u1_bytes = [
        167, 187, 97, 236, 186, 142, 64, 10, 154, 118, 213, 174, 1, 78, 135, 255,
        88, 151, 182, 93, 163, 181, 149, 168, 19, 208, 253, 203, 206, 13, 49, 111,
        118, 108, 238, 235, 111, 248, 76, 222, 204, 214, 155, 224, 231, 179, 153, 209
    ];

    let u1_bytes_to_registers = bytes_to_registers(u1_bytes);
    let expected_u1_bytes_to_registers = BigNum::from_array([0x1be76a03518b044daaa0f2e4689e00, 0xb65da3b595a813d0fdcc75c895dc53, 0x5897]);
    assert(u1_bytes_to_registers == expected_u1_bytes_to_registers);
}
