use crate::expand_message_xmd::ExpandMessageXmd;
use crate::constants::SECP256K1_PRIME;
use dep::std::bigint::Secpk1Fq;
use crate::biguint::BigUint;

pub fn hash_to_field<N>(msg: [u8; N]) -> [[u8; 32]; 2] {
    let expand_message_xmd = ExpandMessageXmd(msg);

    let mut u0_bytes_to_registers = [0 as u8; 48];
    let mut u1_bytes_to_registers = [0 as u8; 48];

    for i in 0..48 {
        u0_bytes_to_registers[i] = expand_message_xmd[i];
        u1_bytes_to_registers[i] = expand_message_xmd[48 + i];
    }

    let u0_bytes_to_registers = BytesToRegisters(u0_bytes_to_registers);
    let u1_bytes_to_registers = BytesToRegisters(u1_bytes_to_registers);
    [u0_bytes_to_registers, u1_bytes_to_registers]
}

fn BytesToRegisters(ui: [u8; 48]) -> [u8; 32] {
    // Need to convert in Big Endian format
    let a = BigUint::from_bytes(
        &[
        ui[47], ui[46], ui[45], ui[44], ui[43], ui[42], ui[41], ui[40],
        ui[39], ui[38], ui[37], ui[36], ui[35], ui[34], ui[33], ui[32],
        ui[31], ui[30], ui[29], ui[28], ui[27], ui[26], ui[25], ui[24],
        ui[23], ui[22], ui[21], ui[20], ui[19], ui[18], ui[17], ui[16],
        ui[15], ui[14], ui[13], ui[12], ui[11], ui[10], ui[9], ui[8],
        ui[7], ui[6], ui[5], ui[4], ui[3], ui[2], ui[1], ui[0],
    ]
    );

    let (_quo, rem) = a.div(BigUint::from_bytes(SECP256K1_PRIME));
    rem.to_bytes_32()

    // for [[u64; 4]; 2] output.
    // I think it's better to save in byte format
    
    /*
    // Convertion from [u8; 8] to u64, Little Endian
    
    let mut res = [0 as u64; 4];
    for i in 0..4 {
        for j in 0..8 {
            res[i] += (256 as Field).pow_32(j as Field) as u64 * rem[i*8 + j] as u64;
        }
    }
    res
    */
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
