use std::bigint::Secpk1Fq;
use crate::ec_ops::Point;
use crate::utils::mod_sqrt;
use crate::constants::{ZERO, ONE, SECP256K1_PRIME};

// Constants are taken from the .circom code, converted to a little endian bytes array
// https://github.com/geometryxyz/secp256k1_hash_to_curve/blob/main/circuits/circom/constants.circom
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

fn xy2_selector(x1: Secpk1Fq, x2: Secpk1Fq, gx1: Secpk1Fq, gx2: Secpk1Fq) -> (Secpk1Fq, Secpk1Fq) {
    let gx1_sqrt = mod_sqrt(gx1);
    let gx2_sqrt = mod_sqrt(gx2);

    let s1 = gx1_sqrt * gx1_sqrt == gx1;
    let s2 = gx2_sqrt * gx2_sqrt == gx2;
    assert(s1 ^ s2);

    if s1 { (x1, gx1_sqrt) } else { (x2, gx2_sqrt) }
}

// As a result, we get a point not on the Secp256k1 curve, but a point E' that isogeny to this curve
// Formula from https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-simplified-shallue-van-de-w
pub fn map_to_curve(u: Secpk1Fq) -> Point {
    let z = Secpk1Fq::from_le_bytes(get_z());

    let tv1 = Secpk1Fq::from_le_bytes(&[1]) / (z * z * u * u * u * u + z * u * u);
    let a = Secpk1Fq::from_le_bytes(get_a());
    let b = Secpk1Fq::from_le_bytes(get_b());
    let x1 = ((ZERO - b) / a) * (ONE + tv1);

    let gx1 = x1 * x1 * x1 + a * x1 + b;
    let x2 = z * u * u * x1;
    let gx2 = x2 * x2 * x2 + a * x2 + b;
    let (x, y) = xy2_selector(x1, x2, gx1, gx2);

    let left_sgn  = (u.to_le_bytes()[0] as Field).to_le_bits(8)[0];
    let right_sgn = (y.to_le_bytes()[0] as Field).to_le_bits(8)[0];

    let y = if left_sgn == right_sgn { y } else { ZERO - y };
    (x, y)
}

#[test]
fn test_mod_mul_inv_x1() {
    let x1 = Secpk1Fq::from_le_bytes(
        &[
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ]
    );

    let inv_x1 = Secpk1Fq::from_le_bytes(&[1]) / x1;
    let expected_inv_x1: [u8] = [
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ];
    assert(inv_x1.to_le_bytes() == expected_inv_x1);
}

#[test]
fn test_xy2_selector_1() {
    let x1 = Secpk1Fq::from_le_bytes(&[123]);
    let x2 = Secpk1Fq::from_le_bytes(&[200, 1]);
    let gx1 = Secpk1Fq::from_le_bytes(&[4]);
    let gx2 = Secpk1Fq::from_le_bytes(&[5]);

    let (actual_x, actual_gx) = xy2_selector(x1, x2, gx1, gx2);
    assert(actual_x == x1);
    assert(actual_gx == Secpk1Fq::from_le_bytes(&[2]));
}

#[test]
fn test_xy2_selector_2() {
    let x1 = Secpk1Fq::from_le_bytes(&[123]);
    let x2 = Secpk1Fq::from_le_bytes(&[200, 1]);
    let gx1 = Secpk1Fq::from_le_bytes(&[5]);
    let gx2 = Secpk1Fq::from_le_bytes(&[4]);

    let (actual_x, actual_gx) = xy2_selector(x1, x2, gx1, gx2);
    assert(actual_x == x2);
    assert(actual_gx == Secpk1Fq::from_le_bytes(&[2]));
}

#[test]
fn test_map_to_curve() {
    let u0_bytes = Secpk1Fq::from_le_bytes(
        &[
        97, 43, 138, 176, 151, 243, 115, 72,
        138, 225, 103, 71, 84, 31, 73, 62,
        244, 209, 206, 148, 223, 59, 30, 96,
        247, 161, 121, 54, 93, 171, 138, 18
    ]
    );

    let (x, y) = map_to_curve(u0_bytes);

    let expected_x = Secpk1Fq::from_le_bytes(
        &[
        181, 145, 157, 194, 47, 137, 194, 182,
        137, 175, 255, 248, 220, 155, 21, 208,
        170, 147, 24, 158, 1, 255, 122, 7,
        138, 168, 206, 231, 17, 190, 219, 242
    ]
    );
    let expected_y = Secpk1Fq::from_le_bytes(
        &[
        229, 169, 131, 251, 47, 167, 25, 23,
        58, 145, 104, 47, 28, 167, 183, 142,
        222, 47, 130, 14, 237, 125, 44, 130,
        236, 154, 191, 129, 133, 161, 34, 59
    ]
    );

    assert(x == expected_x);
    assert(y == expected_y);
}
