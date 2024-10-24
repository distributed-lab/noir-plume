use crate::constants::ZERO;
use bignum::BigNum;
use crate::constants::Fq;

pub type Point = (Fq, Fq);

// Operations taken from the http://delta.cs.cinvestav.mx/~francisco/cripto/ellipticbg.pdf doc
pub fn point_add(p0: Point, p1: Point) -> Point {
    let (x0, y0) = p0;
    let (x1, y1) = p1;

    let lambda = (y1 - y0) / (x1 - x0);
    let x2 = lambda * lambda - x0 - x1;
    let y2 = lambda * (x0 - x2) - y0;
    (x2, y2)
}

fn double_point(p: Point) -> Point {
    let (x, y) = p;
    let two = BigNum::from_array([2, 0, 0]);
    let three = BigNum::from_array([3, 0, 0]);

    let lambda = (three * x * x) / (two * y);
    let x3 = lambda * lambda - two * x;
    let y3 = lambda * (x - x3) - y;
    (x3, y3)
}

pub fn point_mul(scalar: [u8; 32], mut p: Point) -> Point {
    let mut res = (ZERO, ZERO);
    let mut first_add = true;

    for i in 0..32 {
        for j in 0..8 {
            if scalar[i] & (1 << j) != 0 {
                if first_add {
                    res = p;
                    first_add = false;
                } else {
                    res = point_add(res, p);
                }
            }
            p = double_point(p);
        }
    }
    res
}

#[test]
fn test_point_add_with_msg_abc() {
    let p0 = (
        BigNum::from_array([0x6604ccbbbadad8523b8fc38a5322d7, 0x9432d426845fb19857d1b3a9172243, 0x7dd]), BigNum::from_array([0xe0e523bbaf1bed4014a467122eb33f, 0x88ef5138cffe3277bbd590b8550bcb, 0x6045])
    );
    let p1 = (
        BigNum::from_array([0x6b8dac05f8491eb88764fc65321f78, 0x9794d15d4e77dde751e06c18278204, 0xe9ef]), BigNum::from_array([0x2dd76314aa41f012919fe8e7f717b3, 0xce53670d5314bf236ee2c871455c56, 0xcb07])
    );

    let actual_p = point_add(p0, p1);
    let expected_p = (
        BigNum::from_array([0xb6ecf9f9205760bd9ff11fb3cb2c4b, 0xe01eab42db296b512293120c6cee72, 0x3377]), BigNum::from_array([0xfb6116f94688d487c6c7b9c8371f6, 0x890f33efebd1044d382a01b1bee090, 0x7f95])
    );
    assert(actual_p == expected_p);
}

#[test]
fn test_double_point() {
    let p = (
        BigNum::from_array([0x2affbc49c54d1136a2190db0800b65, 0x2d0e12679f23c218889395abcdc01f, 0xbcac]), BigNum::from_array([0xa91a53e32b3752145d87f0cd70966e, 0xb339c974c0e757d348081f90a123b0, 0x3bcf])
    );

    let actual_p = double_point(p);
    let expected_p = (
        BigNum::from_array([0xd8d0efa7dcf721e0dba86a00aec8cd, 0x688008eb81d1e7e3a81df0e34120a0, 0x9ecb]), BigNum::from_array([0xa6480d893bc063ee11ca12ca8e3c77, 0x7d646834bfcb7145349ff0128d0b67, 0x7a40])
    );
    assert(actual_p == expected_p);
}

#[test]
fn point_mul_with_scalar() {
    let p = (
        BigNum::from_array([0x2affbc49c54d1136a2190db0800b65, 0x2d0e12679f23c218889395abcdc01f, 0xbcac]), BigNum::from_array([0xa91a53e32b3752145d87f0cd70966e, 0xb339c974c0e757d348081f90a123b0, 0x3bcf])
    );
    let scalar = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];

    let actual_p = point_mul(scalar, p);
    let expected_p: Point = (
        BigNum::from_array([0xc5a66473a45c1e626f1d0c67e55830, 0x3ed28172ef8adde4b9e0c2cce745fc, 0x57bc]), BigNum::from_array([0x9f3ae67ea38fa891d6087fe59ecb73, 0x41488d58f33ae46edd2188e111609f, 0x6a2f])
    );
    assert(actual_p == expected_p);
}
