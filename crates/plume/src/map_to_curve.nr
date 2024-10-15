use bignum::BigNum;
use crate::constants::{Fq, ZERO};
use crate::ec_ops::Point;
use crate::utils::mod_sqrt;

// Constants are taken from the .circom code, converted to a little endian bytes array
// https://github.com/geometryxyz/secp256k1_hash_to_curve/blob/main/circuits/circom/constants.circom
fn get_z() -> [Field; 3] {
    [0xfffffffffffffffffffffefffffc24, 0xffffffffffffffffffffffffffffff, 0xffff]
}

fn get_a() -> [Field; 3] {
    [0x53d363cb6f0e5d405447c01a444533, 0x31abdd661adca08a5558f0f5d272e9, 0x3f87]
}

fn get_b() -> [Field; 3] {
    [0x6eb, 0, 0]
}

fn xy2_selector(x1: Fq, x2: Fq, gx1: Fq, gx2: Fq) -> Point {
    let gx1_sqrt = mod_sqrt(gx1);
    let gx2_sqrt = mod_sqrt(gx2);

    let s1 = gx1_sqrt * gx1_sqrt == gx1;
    let s2 = gx2_sqrt * gx2_sqrt == gx2;
    assert(s1 ^ s2);

    if s1 { (x1, gx1_sqrt) } else { (x2, gx2_sqrt) }
}

// As a result, we get a point not on the Secp256k1 curve, but a point E' that isogeny to this curve
// Formula from https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-simplified-shallue-van-de-w
pub fn map_to_curve(u: Fq) -> Point {
    let z = BigNum::from_array(get_z());

    let tv1 = BigNum::one() / (z * z * u * u * u * u + z * u * u);
    let a = BigNum::from_array(get_a());
    let b = BigNum::from_array(get_b());
    let x1 = ((ZERO - b) / a) * (BigNum::one() + tv1);

    let gx1 = x1 * x1 * x1 + a * x1 + b;
    let x2 = z * u * u * x1;
    let gx2 = x2 * x2 * x2 + a * x2 + b;
    let (x, y) = xy2_selector(x1, x2, gx1, gx2);

    let ubyte: [u8; 32] = u.to_le_bytes();
    let ybyte: [u8; 32] = y.to_le_bytes();
    let left:  [u1; 8] = (ubyte[0] as Field).to_le_bits();
    let right: [u1; 8] = (ybyte[0] as Field).to_le_bits();

    let y = if left[0] == right[0] { y } else { ZERO - y };
    (x, y)
}

// TODO uncomment later
#[test]
fn test_mod_mul_inv_x1() {
    let x1: Fq = BigNum::from_array([0x387936733e29cddb43759809208354, 0xc334daf72303fb27f6aad8201a9465, 0xc6f1]);

    let inv_x1 = BigNum::one() / x1;
    let expected_inv_x1: [u8; 32] = [
        211, 142, 221, 78, 176, 90, 13, 18,
        140, 253, 186, 38, 111, 230, 156, 220,
        55, 89, 204, 218, 31, 162, 175, 33,
        15, 146, 219, 86, 70, 80, 101, 19
    ];
    assert(inv_x1.to_le_bytes() == expected_inv_x1);
}

#[test]
fn test_xy2_selector_1() {
    let x1 = BigNum::from_array([123, 0, 0]);
    let x2 = BigNum::from_array([200, 0, 0]);
    let gx1 = BigNum::from_array([4, 0, 0]);
    let gx2 = BigNum::from_array([5, 0, 0]);

    let (actual_x, actual_gx) = xy2_selector(x1, x2, gx1, gx2);
    assert(actual_x == x1);
    assert(actual_gx == BigNum::from_array([2, 0, 0]));
}

#[test]
fn test_xy2_selector_2() {
    let x1 = BigNum::from_array([123, 0, 0]);
    let x2 = BigNum::from_array([200, 1, 0]);
    let gx1 = BigNum::from_array([5, 0, 0]);
    let gx2 = BigNum::from_array([4, 0, 0]);

    let (actual_x, actual_gx) = xy2_selector(x1, x2, gx1, gx2);
    assert(actual_x == x2);
    assert(actual_gx == BigNum::from_array([2, 0, 0]));
}

#[test]
fn test_map_to_curve() {
    let u0_bytes = BigNum::from_array([0x491f544767e18a4873f397b08a2b61, 0xab5d3679a1f7601e3bdf94ced1f43e, 0x128a]);

    let (x, y) = map_to_curve(u0_bytes);

    let expected_x = [
        181, 145, 157, 194, 47, 137, 194, 182,
        137, 175, 255, 248, 220, 155, 21, 208,
        170, 147, 24, 158, 1, 255, 122, 7,
        138, 168, 206, 231, 17, 190, 219, 242
    ];
    let expected_y = [
        229, 169, 131, 251, 47, 167, 25, 23,
        58, 145, 104, 47, 28, 167, 183, 142,
        222, 47, 130, 14, 237, 125, 44, 130,
        236, 154, 191, 129, 133, 161, 34, 59
    ];

    assert(x.to_le_bytes() == expected_x);
    assert(y.to_le_bytes() == expected_y);
}
