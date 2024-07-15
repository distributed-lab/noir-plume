use crate::biguint::BigUint;
use crate::constants::SECP256K1_PRIME;

// Constants
fn get_k_1_0() -> [u8; 32] {
    [
        199, 168, 170, 170, 141, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142
    ]
}
fn get_k_1_1() -> [u8; 32] {
    [
        129, 101, 124, 241, 68, 16, 255, 223, 146, 59, 246, 11, 252, 210, 149, 213, 197, 68, 253, 167, 206, 21, 243, 185, 213, 33, 195, 11, 200, 212, 211, 7
    ]
}
fn get_k_1_2() -> [u8; 32] {
    [
        98, 210, 157, 61, 181, 208, 203, 78, 49, 64, 124, 3, 68, 97, 80, 228, 236, 202, 37, 202, 222, 19, 164, 226, 230, 52, 242, 35, 141, 50, 76, 83
    ]
}
fn get_k_1_3() -> [u8; 32] {
    [
        140, 168, 170, 170, 141, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142, 227, 56, 142
    ]
}

fn get_k_2_0() -> [u8; 32] {
    [
        155, 180, 30, 120, 69, 183, 230, 159, 125, 72, 248, 66, 149, 64, 205, 134, 221, 64, 182, 183, 203, 76, 163, 156, 138, 145, 148, 61, 25, 113, 87, 211
    ]
}
fn get_k_2_1() -> [u8; 32] {
    [
        20, 109, 140, 42, 97, 86, 42, 197, 187, 65, 94, 31, 100, 107, 211, 6, 84, 34, 84, 27, 213, 178, 196, 247, 29, 220, 131, 67, 246, 198, 173, 237
    ]
}

fn get_k_3_0() -> [u8; 32] {
    [
        60, 226, 56, 142, 75, 104, 47, 161, 189, 132, 246, 18, 218, 75, 104, 47, 161, 189, 132, 246, 18, 218, 75, 104, 47, 161, 189, 132, 246, 18, 218, 75
    ]
}
fn get_k_3_1() -> [u8; 32] {
    [
        163, 113, 29, 32, 252, 144, 252, 223, 111, 218, 134, 214, 70, 176, 122, 100, 213, 166, 160, 18, 75, 165, 208, 169, 15, 124, 203, 213, 50, 12, 94, 199
    ]
}
fn get_k_3_2() -> [u8; 32] {
    [
        49, 233, 206, 158, 90, 232, 101, 167, 24, 32, 190, 1, 162, 48, 40, 114, 118, 229, 18, 101, 239, 9, 82, 113, 115, 26, 249, 145, 70, 25, 166, 41
    ]
}
fn get_k_3_3() -> [u8; 32] {
    [
        132, 141, 227, 56, 47, 161, 189, 132, 246, 18, 218, 75, 104, 47, 161, 189, 132, 246, 18, 218, 75, 104, 47, 161, 189, 132, 246, 18, 218, 75, 104, 47
    ]
}

fn get_k_4_0() -> [u8; 32] {
    [
        59, 249, 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
    ]
}
fn get_k_4_1() -> [u8; 32] {
    [
        115, 37, 92, 104, 210, 37, 180, 223, 120, 217, 232, 200, 191, 193, 103, 148, 152, 194, 34, 39, 99, 230, 233, 213, 159, 180, 189, 184, 75, 83, 6, 122
    ]
}
fn get_k_4_2() -> [u8; 32] {
    [
        111, 167, 210, 191, 146, 129, 191, 167, 153, 98, 13, 47, 22, 33, 61, 10, 126, 51, 254, 168, 63, 12, 167, 243, 44, 202, 69, 101, 113, 170, 132, 100
    ]
}

pub fn IsoMap(x: [u8; 32], y: [u8; 32], x_mapped: [u8; 32], y_mapped: [u8; 32]) {
    let x = BigUint::from_bytes_32(x);
    let p = BigUint::from_bytes_32(SECP256K1_PRIME);

    // Step 1. Calculate x^2
    let x_2 = x.mul(x).div(p).1;

    // Step 2. Calculate x^3
    let x_3 = x_2.mul(x).div(p).1;

    let x_num = XNum(x, x_2, x_3);
    let x_den = XDen(x, x_2);
    let y_num = YNum(x, x_2, x_3);
    let y_den = YDen(x, x_2, x_3);

    // We need to check provided mapped values with calculated
    // x_mapped * x_den === x_num
    let res_x = x_num.div(x_den);
    assert(BigUint::from_bytes_32(x_mapped).mul(x_den).div(p).1.eq(x_num));
    
    let left = BigUint::from_bytes_32(y_mapped).mul(y_den);
    let right = BigUint::from_bytes_32(y).mul(y_num);
    assert(left.eq(right));
}

fn XNum(x: BigUint, x_2: BigUint, x_3: BigUint) -> BigUint {
    /*
    k_(1,3) * x^3 + 
    k_(1,2) * x^2 + 
    k_(1,1) * x   +
    k_(1,0)
    */

    let p = BigUint::from_bytes_32(SECP256K1_PRIME);
    let a = BigUint::from_bytes_32(get_k_1_3()).mul(x_3).div(p).1;
    let b = BigUint::from_bytes_32(get_k_1_2()).mul(x_2).div(p).1;
    let c = BigUint::from_bytes_32(get_k_1_1()).mul(x).div(p).1;
    a.add(b).add(c).add(BigUint::from_bytes_32(get_k_1_0())).div(p).1
}

fn XDen(x: BigUint, x_2: BigUint) -> BigUint {
    let p = BigUint::from_bytes_32(SECP256K1_PRIME);
    let a = BigUint::from_bytes_32(get_k_2_1()).mul(x).div(p).1;
    BigUint::from_bytes_32(get_k_2_0()).add(x_2).add(a).div(p).1
}

fn YNum(x: BigUint, x_2: BigUint, x_3: BigUint) -> BigUint {
    let p = BigUint::from_bytes_32(SECP256K1_PRIME);
    let a = BigUint::from_bytes_32(get_k_3_3()).mul(x_3).div(p).1;
    let b = BigUint::from_bytes_32(get_k_3_2()).mul(x_2).div(p).1;
    let c = BigUint::from_bytes_32(get_k_3_1()).mul(x).div(p).1;
    BigUint::from_bytes_32(get_k_3_0()).add(a).add(b).add(c).div(p).1
}

fn YDen(x: BigUint, x_2: BigUint, x_3: BigUint) -> BigUint {
    let p = BigUint::from_bytes_32(SECP256K1_PRIME);
    let a = BigUint::from_bytes_32(get_k_4_2()).mul(x_2).div(p).1;
    let b = BigUint::from_bytes_32(get_k_4_1()).mul(x).div(p).1;
    BigUint::from_bytes_32(get_k_4_0()).add(x_3).add(a).add(b).div(p).1
}


#[test]
fn test_IsoMap() {
    let x = [
        120, 31, 50, 101, 252, 100, 135, 184,
        30, 73, 248, 5, 172, 141, 107, 4,
        130, 39, 24, 108, 224, 81, 231, 221,
        119, 78, 93, 209, 148, 151, 239, 233
    ];
    let y = [
        179, 23, 247, 231, 232, 159, 145, 18,
        240, 65, 170, 20, 99, 215, 45, 86,
        92, 69, 113, 200, 226, 110, 35, 191,
        20, 83, 13, 103, 83, 206, 7, 203
    ];

    let x_mapped = [
        248, 159, 226, 176, 248, 57, 16, 215,
        154, 253, 32, 122, 148, 42, 124, 230,
        67, 118, 80, 123, 130, 94, 244, 92,
        254, 0, 94, 26, 38, 109, 157, 248
    ];
    let y_mapped = [
        87, 175, 108, 128, 252, 207, 29, 238,
        28, 188, 99, 213, 54, 233, 28, 203,
        170, 177, 172, 195, 198, 145, 173, 110,
        23, 169, 52, 204, 224, 85, 56, 179
    ];

    IsoMap(x, y, x_mapped, y_mapped);
}
