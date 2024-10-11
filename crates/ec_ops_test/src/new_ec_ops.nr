use bignum::BigNum;
use bignum::fields::secp256k1Fq::Secp256k1_Fq_Params;

type Fq = BigNum<3, Secp256k1_Fq_Params>;
type Point = (Fq, Fq);
global ZERO = BigNum::from_array([0, 0, 0]);

fn point_add(p0: Point, p1: Point) -> Point {
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

fn point_mul(scalar: [u8; 32], mut p: Point) -> Point {
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

/*
let p0: Point = (BigNum::from_array([0x436604ccbbbadad8523b8fc38a5322d7, 0x7dd9432d426845fb19857d1b3a91722, 0]),
        BigNum::from_array([0xcbe0e523bbaf1bed4014a467122eb33f, 0x604588ef5138cffe3277bbd590b8550b, 0]));
        */
pub fn test_new_point_mul() {
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
    // let zero = (ZERO, ZERO);
    assert(actual_p == expected_p);
}
