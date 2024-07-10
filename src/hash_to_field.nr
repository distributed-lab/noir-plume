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
