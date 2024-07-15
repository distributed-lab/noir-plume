use crate::biguint::BigUint;
use crate::constants::{
    SECP256K1_PRIME, Z, C1, C2, A, B
};

use dep::std::bigint::Secpk1Fq;

// For now I don't know the output format
pub fn MapToCurve(u: [u8; 32]) -> ([u8; 32], [u8; 32]) {
    // ? - don't know how to implement now

    // Step 1. tv1 = (Z * u^2) % p 
    let big_u = BigUint::from_bytes_32(u);
    let p = BigUint::from_bytes_32(SECP256K1_PRIME);
    let tv1 = BigUint::from_bytes_32(Z).mul(big_u).mul(big_u).div(p).1;

    // Step 2. tv2 = tv1^2 % p
    let tv2 = tv1.mul(tv1).div(p).1;
    
    // Step 3. x1 = (tv1 + tv2) % p
    // Step 4. x1 = inv0(x1) - modular multiplicative inverse
    let x1 = tv1.add(tv2).div(p).1; //.mod_mul_inv(p);

    /*
    let x1 = BigUint::from_bytes(&[
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ]);
    */

    // Step 5. eq = x1 == 0
    // Step 6. x1 += 1
    // Step 7. x1 = CMOV(x1, c2, e1)
    // Maybe we don't need step with e1. This is not present in the TS code
    let x1 = (if x1.eq(BigUint::zero()) { BigUint::from_bytes_32(C2) } else { x1 }).add(BigUint::one());
    
    // Step 8. x1 = (x1 * c1) % p
    let x1 = x1.mul(BigUint::from_bytes_32(C1));

    // Step 9. gx1 = x1^2 % p
    let gx1 = x1.mul(x1).div(p).1;

    // Step 10. gx1 = (gx1 + A) % p
    let gx1 = gx1.add(BigUint::from_bytes_32(A)).div(p).1;

    // Step 11. gx1 = (gx1 * x1) % p
    let gx1 = gx1.mul(x1).div(p).1;

    // Step 12. gx1 = (gx1 + B) % p
    let gx1 = gx1.add(BigUint::from_bytes(B)).div(p).1;

    // Step 13. x2 = (tv1 * x1) % p
    let x2 = tv1.mul(x1).div(p).1;

    // Step 14. tv2 = (tv1 * tv2) % p
    let tv2 = tv1.mul(tv2).div(p).1;

    // Step 15. gx2 = (gx1 * tv2) % p
    let gx2 = gx1.mul(tv2).div(p).1;

    // Steps 16-18.
    let (x, y2) = XY2Selector(x1, x2, gx1, gx2);

    // Step 19. y = sqrt(y2)
    let y = y2.sqrt();
    assert(y.mul(y).eq(y2));

    // Step 20. e3 = is_even(u) == is_even(y)
    // step 21. y = e3 ? y : -y
    // Res y = (p - y) % p
    let y = if big_u.is_even() == y.is_even() { y } else { y.negative() };
    (x.to_bytes_32(), p.sub(y).div(p).1.to_bytes_32())
}

pub fn XY2Selector(x1: BigUint, x2: BigUint, gx1: BigUint, gx2: BigUint) -> (BigUint, BigUint) {
    let gx1_sqrt = gx1.sqrt();
    let gx2_sqrt = gx2.sqrt();

    let s1 = gx1_sqrt.mul(gx1_sqrt).eq(gx1);
    let s2 = gx2_sqrt.mul(gx2_sqrt).eq(gx2);
    assert(s1 ^ s2);

    if s1 {
        (x1, gx1)
    } else {
        (x2, gx2)
    }
}

#[test]
fn test_tv1() {
    // tv1 = (Z * u^2) % p 
    let u = [
        97, 43, 138, 176, 151, 243, 115, 72,
        138, 225, 103, 71, 84, 31, 73, 62,
        244, 209, 206, 148, 223, 59, 30, 96,
        247, 161, 121, 54, 93, 171, 138, 18
    ];

    //let big_u0::from

    let big_u0 = BigUint::from_bytes_32(u);
    let big_z = BigUint::from_bytes_32(Z);
    let big_P = BigUint::from_bytes_32(SECP256K1_PRIME);
    let tv1 = big_z.mul(big_u0).mul(big_u0).div(big_P).1;
    
    let expected_tv1 = [
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ];
    assert(tv1.to_bytes_32() == expected_tv1);
}

#[test]
fn test_tv2() {
    // tv2 = tv1^2 % p
    let tv1 = BigUint::from_bytes_32([
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ]);
    let tv2 = tv1.mul(tv1).div(BigUint::from_bytes_32(SECP256K1_PRIME)).1;

    let expected_tv2 = [
        156, 107, 5, 192, 90, 40, 223, 212,
        130, 84, 167, 237, 236, 226, 136, 183,
        80, 34, 225, 160, 109, 225, 215, 3,
        219, 33, 19, 240, 188, 234, 211, 152
    ];
    assert(tv2.to_bytes_32() == expected_tv2);
}

#[test]
fn test_step_3() {
    // x1 = (tv1 + tv2) % p
    let tv1 = BigUint::from_bytes_32([
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ]);
    let tv2 = BigUint::from_bytes_32([
        156, 107, 5, 192, 90, 40, 223, 212,
        130, 84, 167, 237, 236, 226, 136, 183,
        80, 34, 225, 160, 109, 225, 215, 3,
        219, 33, 19, 240, 188, 234, 211, 152
    ]);


    let x1 = tv1.add(tv2).div(BigUint::from_bytes_32(SECP256K1_PRIME)).1;
    let expected_x1 = [
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ];
    assert(x1.to_bytes_32() == expected_x1);
}

/*
// Failed
// Frozes the OS. Too hard for compiler
#[test]
fn test_steps_4_5() {
    // mod_mul_inv(x1)
    let x1 = BigUint::from_bytes_32([
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ]);

    let inv_x1 = x1.mod_mul_inv(BigUint::from_bytes_32(SECP256K1_PRIME));
    let expected_inv_x1 = [
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ];
    assert(inv_x1.to_bytes_32() == expected_inv_x1);
}
*/

// TODO: Need to know the expected result
#[test]
fn test_x1() {
    // x1 += 1
    // x1 = (x1 * c1) % p
    let x1 = BigUint::from_bytes_32([
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ]);

    let x1 = x1.add(BigUint::one());
    let x1 = x1.mul(BigUint::from_bytes_32(C1)).div(BigUint::from_bytes_32(SECP256K1_PRIME)).1;

    let expected_x1 = [
        0 as u8; 32
    ];
    assert(x1.to_bytes_32() == expected_x1);
}

#[test]
fn test_XY2Selector_1() {
    let gx1 = BigUint::from_bytes(&[4]);
    let gx2 = BigUint::from_bytes(&[5]);
    let x1 = BigUint::from_bytes(&[123]);
    let x2 = BigUint::from_bytes(&[200, 1]);

    let (expected_x1, expected_gx1) = XY2Selector(x1, x2, gx1, gx2);
    assert(expected_x1.eq(x1));
    assert(expected_gx1.eq(gx1));
}

#[test]
fn test_XY2Selector_2() {
    let gx1 = BigUint::from_bytes(&[5]);
    let gx2 = BigUint::from_bytes(&[4]);
    let x1 = BigUint::from_bytes(&[123]);
    let x2 = BigUint::from_bytes(&[200, 1]);

    let actual = XY2Selector(x1, x2, gx1, gx2);
    assert(actual.0.eq(x2));
    assert(actual.1.eq(gx2));
}

// Failed
// Frozes the OS
#[test]
fn test_MapToCurve() {
    let u0_bytes = [
        97, 43, 138, 176, 151, 243, 115, 72,
        138, 225, 103, 71, 84, 31, 73, 62,
        244, 209, 206, 148, 223, 59, 30, 96,
        247, 161, 121, 54, 93, 171, 138, 18
    ];

    let (x, y) = MapToCurve(u0_bytes);
    let expected_x = [
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ];
    let expected_y = [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ];
    
    assert(x == expected_x);
    assert(y == expected_y);
}
