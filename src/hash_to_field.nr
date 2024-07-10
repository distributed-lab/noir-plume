use crate::expand_message_xmd::ExpandMessageXmd;
use crate::constants::SECP256K1_PRIME;
use dep::std::bigint::Secpk1Fq;
use crate::biguint::BigUint;

fn hash_to_field<N>(msg: [u8; N]) -> Field {
    let expand_message_xmd = ExpandMessageXmd(msg);

    let mut u0_bytes_to_registers = [0 as u8; 48];
    let mut u1_bytes_to_registers = [0 as u8; 48];

    for i in 0..48 {
        u0_bytes_to_registers[i] = expand_message_xmd[i];
        u1_bytes_to_registers[i] = expand_message_xmd[48 + i];
    }

    //println(u1_bytes_to_registers);

    // let u0_bytes_to_registers = BytesToRegisters(u0_bytes_to_registers);
    let u1_bytes_to_registers = BytesToRegisters(u1_bytes_to_registers);

    0
}

fn BytesToRegisters(ui: [u8; 48]) -> [u64; 4] {
    // 48 bytes would not fit, so I decided to cut them off
    let a = BigUint::from_bytes(
        &[
        ui[0], ui[1], ui[2], ui[3], ui[4], ui[5], ui[6], ui[7],
        ui[8], ui[9], ui[10], ui[11], ui[12], ui[13], ui[14], ui[15], ui[16], ui[17], ui[18],
        ui[19], ui[20], ui[21], ui[22], ui[23], ui[24], ui[25], ui[26], ui[27], ui[28], ui[29], ui[30], ui[31],
        ui[32], ui[33], ui[34], ui[35], ui[36], ui[37], ui[38], ui[39], ui[40], ui[41],
        ui[42], ui[43], ui[44], ui[45], ui[46], ui[47]
    ]
    );

    let (_quo, rem) = a.div(BigUint::from_bytes(SECP256K1_PRIME));
    println(rem);

    /* // result. Consistent with python tests, but not with circom
    BigUint { bytes: [253, 169, 77, 85, 84, 30, 239, 89,
                      230, 50, 225, 191, 190, 188, 186, 203,
                      96, 78, 80, 47, 164, 181, 149, 168,
                      19, 208, 253, 203, 206, 13, 49, 111,
                      0, 0, 0, 0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0, 0, 0, 0] }
    */
    [0; 4]
}
