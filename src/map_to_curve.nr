use dep::std::bigint::Secpk1Fq;
use crate::biguint::BigUint;
use crate::constants::SECP256K1_PRIME;
use crate::utils::{
    to_u8_arr, to_u8_32
};

fn get_z() -> [u8] {
    [
        36, 252, 255, 255, 254, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255
    ]
}

fn get_c1() -> [u8] {
    [
        195, 69, 35, 141, 142, 213, 1, 170,
        253, 116, 45, 232, 152, 255, 244, 109,
        12, 123, 232, 211, 245, 77, 12, 160,
        178, 56, 133, 113, 238, 108, 197, 11
    ]
}

fn get_c2() -> [u8] {
    [
        106, 208, 69, 23, 116, 209, 69, 23,
        93, 116, 209, 69, 23, 93, 116, 209,
        69, 23, 93, 116, 209, 69, 23, 93,
        116, 209, 69, 23, 93, 116, 209, 69
    ]
}

fn get_a() -> [u8] {
    [
        51, 69, 68, 26, 192, 71, 84, 64,
        93, 14, 111, 203, 99, 211, 83, 233,
        114, 210, 245, 240, 88, 85, 138, 160,
        220, 26, 102, 221, 171, 49, 135, 63
    ]
}

fn get_b() -> [u8] {
    [235, 6]
}

// https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#simple-swu
pub fn MapToCurve(u: [u8; 32]) -> ([u8; 32], [u8; 32]) {
    let u = Secpk1Fq::from_le_bytes(to_u8_arr(u));
    let z = Secpk1Fq::from_le_bytes(get_z());
    
    let tv1 = mod_mul_inv(z*z * u*u*u*u + z * u*u);
    let a = Secpk1Fq::from_le_bytes(get_a());
    let b = Secpk1Fq::from_le_bytes(get_b());
    let x1 = ((b - b - b) / a) * (Secpk1Fq::from_le_bytes(&[1]) + tv1);

    let gx1 = x1*x1*x1 + a*x1 + b;
    let x2 = z * u*u * x1;
    let gx2 = x2*x2*x2 + a*x2 + b;
    let (x, y) = XY2Selector(x1, x2, gx1, gx2);

    let y = if BigUint::from_Secpk1Fq(u).is_even() == BigUint::from_Secpk1Fq(y).is_even() {
        y
    } else {
        y - y - y
    };
    (to_u8_32(x.to_le_bytes()), to_u8_32(y.to_le_bytes()))

    /*
    let (x, y) = XY2Selector(
        BigUint::from_Secpk1Fq(x1),
        BigUint::from_Secpk1Fq(x2),
        BigUint::from_Secpk1Fq(gx1),
        BigUint::from_Secpk1Fq(gx2)
    );

    let y = if BigUint::from_Secpk1Fq(u).is_even() == y.is_even() {
        BigUint::to_Secpk1Fq(y)
    } else {
        // -y don't work
        let temp = BigUint::to_Secpk1Fq(y);
        temp - temp - temp
    };
    (x.to_bytes_32(), to_u8_32(y.to_le_bytes()))
    */
}

/*
pub fn MapToCurve(u: [u8; 32]) -> ([u8; 32], [u8; 32]) {
    // ? - don't know how to implement now

    // Step 1. tv1 = (Z * u^2) % p
    let p = Secpk1Fq::from_le_bytes(to_u8_arr(SECP256K1_PRIME));
    let u = Secpk1Fq::from_le_bytes(to_u8_arr(u));
    let tv1 = Secpk1Fq::from_le_bytes(get_z()) * u * u;

    // Step 2. tv2 = tv1^2 % p
    let tv2 = tv1 * tv1;
    
    // Step 3. x1 = (tv1 + tv2) % p
    // Step 4. x1 = inv0(x1) - modular multiplicative inverse
    let x1 = mod_mul_inv(tv1 + tv2);

    // Step 5. eq = x1 == 0
    // Step 6. x1 += 1
    // Step 7. x1 = CMOV(x1, c2, e1)
    // Maybe we don't need step with e1. This is not present in the TS code
    let x1 = (
        if x1 == Secpk1Fq::from_le_bytes(&[0]) {
            Secpk1Fq::from_le_bytes(get_c2())
        } else { x1 }
    ) + Secpk1Fq::from_le_bytes(&[1]);
    
    // Step 8. x1 = (x1 * c1) % p
    let x1 = x1 * Secpk1Fq::from_le_bytes(get_c1());

    // Step 9.  gx1 = x1^2 % p
    // Step 10. gx1 = (gx1 + A) % p
    let gx1 = x1 * x1 + Secpk1Fq::from_le_bytes(get_a());

    // Step 11. gx1 = (gx1 * x1) % p
    // Step 12. gx1 = (gx1 + B) % p
    let gx1 = gx1 * x1 + Secpk1Fq::from_le_bytes(get_b());

    // Step 13. x2 = (tv1 * x1) % p
    let x2 = tv1 * x1;

    // Step 14. tv2 = (tv1 * tv2) % p
    let tv2 = tv1 * tv2;

    // Step 15. gx2 = (gx1 * tv2) % p
    let gx2 = gx1 * tv2;

    // Steps 16-18.
    // Step 19. y = sqrt(input_y)
    let (x, y) = XY2Selector(
        BigUint::from_Secpk1Fq(x1),
        BigUint::from_Secpk1Fq(x2),
        BigUint::from_Secpk1Fq(gx1),
        BigUint::from_Secpk1Fq(gx2)
    );

    // Step 20. e3 = is_even(u) == is_even(y)
    // step 21. y = e3 ? y : -y
    // Res y = (p - y) % p
    let y = if BigUint::from_Secpk1Fq(u).is_even() == y.is_even() {
        BigUint::to_Secpk1Fq(y)
    } else {
        // -y don't work
        let temp = BigUint::to_Secpk1Fq(y);
        temp - temp - temp
    };
    (x.to_bytes_32(), to_u8_32((p - y).to_le_bytes()))
}
*/

// We use the formula R = num^((p+1)/4), since SECP256K1_PRIME % 4 == 3
// https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
fn mod_sqrt(num: Secpk1Fq) -> Secpk1Fq {
    let p_plus_one = Secpk1Fq::from_le_bytes(to_u8_arr(SECP256K1_PRIME)) + Secpk1Fq::from_le_bytes(&[1]);
    bin_pow(num, p_plus_one / Secpk1Fq::from_le_bytes(&[4]))
}

fn XY2Selector(x1: Secpk1Fq, x2: Secpk1Fq, gx1: Secpk1Fq, gx2: Secpk1Fq) -> (Secpk1Fq, Secpk1Fq) {
    let gx1_sqrt = mod_sqrt(gx1);
    let gx2_sqrt = mod_sqrt(gx2);

    let s1 = gx1_sqrt * gx1_sqrt == gx1;
    let s2 = gx2_sqrt * gx2_sqrt == gx2;
    assert(s1 ^ s2);

    /*
    println(gx1);
    println(gx2);
    println("\nsqrt*sqrt");
    println(gx1_sqrt * gx1_sqrt);
    println(gx2_sqrt * gx2_sqrt);
    */

    if s1 {
        (x1, gx1_sqrt)
    } else {
        (x2, gx2_sqrt)
    }
}

// p is SECP256K1_PRIME, then
// mod_mul_inv(a, p) = a ^ (p-2) % p
// use binary power, for O(logN) time complexity
fn mod_mul_inv(mut num: Secpk1Fq) -> Secpk1Fq {
    bin_pow(num, Secpk1Fq::from_le_bytes(to_u8_arr(SECP256K1_PRIME)) - Secpk1Fq::from_le_bytes(&[2]))
}

fn bin_pow(mut num: Secpk1Fq, pow: Secpk1Fq) -> Secpk1Fq {
    let mut res = Secpk1Fq::from_le_bytes(&[1]);
    let mut exp = pow.to_le_bytes();

    for i in 0..exp.len() {
        let byte = (exp[i] as Field).to_le_bits(8);

        for j in 0..8 {
            if byte[j] == 1 {
                res = res * num;
            }
            num = num * num;
        }
    }
    res
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

    let big_u0 = Secpk1Fq::from_le_bytes(to_u8_arr(u));
    let big_z = Secpk1Fq::from_le_bytes(get_z());

    let tv1 = big_z * big_u0 * big_u0;
    
    let expected_tv1: [u8] = [
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ];
    assert(tv1.to_le_bytes() == expected_tv1);
}

#[test]
fn test_tv2() {
    // tv2 = tv1^2 % p
    let tv1 = Secpk1Fq::from_le_bytes(&[
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ]);
    let tv2 = tv1 * tv1;

    let expected_tv2: [u8] = [
        156, 107, 5, 192, 90, 40, 223, 212,
        130, 84, 167, 237, 236, 226, 136, 183,
        80, 34, 225, 160, 109, 225, 215, 3,
        219, 33, 19, 240, 188, 234, 211, 152
    ];
    assert(tv2.to_le_bytes() == expected_tv2);
}

#[test]
fn test_tv1_add_tv2() {
    // x1 = (tv1 + tv2) % p
    let tv1 = Secpk1Fq::from_le_bytes(&[
        184, 23, 27, 73, 61, 77, 100, 6,
        75, 213, 150, 133, 73, 150, 175, 173,
        67, 248, 62, 55, 61, 21, 80, 247,
        40, 1, 228, 234, 119, 216, 29, 46
    ]);
    let tv2 = Secpk1Fq::from_le_bytes(&[
        156, 107, 5, 192, 90, 40, 223, 212,
        130, 84, 167, 237, 236, 226, 136, 183,
        80, 34, 225, 160, 109, 225, 215, 3,
        219, 33, 19, 240, 188, 234, 211, 152
    ]);


    let x1 = tv1 + tv2;
    let expected_x1: [u8] = [
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ];
    assert(x1.to_le_bytes() == expected_x1);
}

#[test]
fn test_mod_mul_inv_x1() {
    // mod_mul_inv(x1)
    let x1 = Secpk1Fq::from_le_bytes(&[
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ]);

    let inv_x1 = mod_mul_inv(x1);
    let expected_inv_x1: [u8] = [
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ];
    assert(inv_x1.to_le_bytes() == expected_inv_x1);
}

// More XY2Selector test, for understand mod_sqrt
#[test]
fn test_XY2Selector_1() {
    let x1 = Secpk1Fq::from_le_bytes(&[123]);
    let x2 = Secpk1Fq::from_le_bytes(&[200, 1]);
    let gx1 = Secpk1Fq::from_le_bytes(&[4]);
    let gx2 = Secpk1Fq::from_le_bytes(&[5]);

    let (actual_x, actual_gx) = XY2Selector(x1, x2, gx1, gx2);
    assert(actual_x == x1);
    assert(actual_gx == Secpk1Fq::from_le_bytes(&[2]));
}

#[test]
fn test_XY2Selector_2() {
    let x1 = Secpk1Fq::from_le_bytes(&[123]);
    let x2 = Secpk1Fq::from_le_bytes(&[200, 1]);
    let gx1 = Secpk1Fq::from_le_bytes(&[5]);
    let gx2 = Secpk1Fq::from_le_bytes(&[4]);

    let (actual_x, actual_gx) = XY2Selector(x1, x2, gx1, gx2);
    assert(actual_x == x2);
    assert(actual_gx == Secpk1Fq::from_le_bytes(&[2]));
}

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
