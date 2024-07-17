// helper methods for convenient Secpk1Fq conversion
pub fn to_u8_arr(smth: [u8; 32]) -> [u8] {
    smth
}

pub fn to_u8_32(smth: [u8]) -> [u8; 32] {
    let mut res = [0 as u8; 32];
    for i in 0..smth.len() {
        res[i] = smth[i];
    }
    res
}
