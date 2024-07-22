use dep::std::bigint::Secpk1Fq;
use crate::constants::ZERO;
use crate::utils::{to_u8_arr, to_u8_32};

type Point = ([u8; 32], [u8; 32]);

// Operations taken from the http://delta.cs.cinvestav.mx/~francisco/cripto/ellipticbg.pdf doc
pub fn PointAdd(p0: Point, p1: Point) -> Point {
    let x0 = Secpk1Fq::from_le_bytes(to_u8_arr(p0.0));
    let y0 = Secpk1Fq::from_le_bytes(to_u8_arr(p0.1));
    let x1 = Secpk1Fq::from_le_bytes(to_u8_arr(p1.0));
    let y1 = Secpk1Fq::from_le_bytes(to_u8_arr(p1.1));

    let lambda = (y1 - y0) / (x1 - x0);
    let x2 = (lambda * lambda - x0 - x1);
    let y2 = (lambda * (x0 - x2) - y0).to_le_bytes();
    (to_u8_32(x2.to_le_bytes()), to_u8_32(y2))
}

// Convenient form for PointMul
fn point_add(x0: Secpk1Fq, y0: Secpk1Fq, x1: Secpk1Fq, y1: Secpk1Fq) -> (Secpk1Fq, Secpk1Fq) {
    let lambda = (y1 - y0) / (x1 - x0);
    let x2 = (lambda * lambda - x0 - x1);
    let y2 = (lambda * (x0 - x2) - y0);
    (x2, y2)
}

fn double_point(x: Secpk1Fq, y: Secpk1Fq) -> (Secpk1Fq, Secpk1Fq) {
    let two = Secpk1Fq::from_le_bytes(&[2]);
    let three = Secpk1Fq::from_le_bytes(&[3]);
    let a = ZERO;

    let lambda = (three * x * x + a) / (two * y);
    let x3 = lambda * lambda - two * x;
    let y3 = lambda * (x - x3) - y;
    (x3, y3)
}

// Can do it without first_add var using point at infinity
pub fn PointMul(scalar: [u8; 32], p: Point) -> Point {
    let mut res = (Secpk1Fq::from_le_bytes(&[0]), Secpk1Fq::from_le_bytes(&[0]));
    let mut p = (Secpk1Fq::from_le_bytes(to_u8_arr(p.0)), Secpk1Fq::from_le_bytes(to_u8_arr(p.1)));
    let mut first_add = true;

    for i in 0..32 {
        let byte = (scalar[i] as Field).to_le_bits(8);

        for j in 0..8 {
            if byte[j] == 1 {
                if first_add {
                    res = p;
                    first_add = false;
                } else {
                    res = point_add(res.0, res.1, p.0, p.1);
                }
            }
            p = double_point(p.0, p.1);
        }
    }
    (to_u8_32(res.0.to_le_bytes()), to_u8_32(res.1.to_le_bytes()))
}

#[test]
fn test_point_add_with_msg_abc() {
    let p0 = ([
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ], [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ]);

    let p1 = ([
        120, 31, 50, 101, 252, 100, 135, 184,
        30, 73, 248, 5, 172, 141, 107, 4,
        130, 39, 24, 108, 224, 81, 231, 221,
        119, 78, 93, 209, 148, 151, 239, 233
    ], [
        179, 23, 247, 231, 232, 159, 145, 18,
        240, 65, 170, 20, 99, 215, 45, 86,
        92, 69, 113, 200, 226, 110, 35, 191,
        20, 83, 13, 103, 83, 206, 7, 203
    ]);

    let actual_p = PointAdd(p0, p1);
    let expected_p = ([
        75, 44, 203, 179, 31, 241, 159, 189,
        96, 87, 32, 249, 249, 236, 182, 114,
        238, 108, 12, 18, 147, 34, 81, 107,
        41, 219, 66, 171, 30, 224, 119, 51
    ], [
        246, 113, 131, 156, 123, 108, 124, 72,
        141, 104, 148, 111, 17, 182, 15, 144,
        224, 190, 177, 1, 42, 56, 77, 4,
        209, 235, 239, 51, 15, 137, 149, 127
    ]);
    assert(actual_p == expected_p);
}

// TODO: Rework
// Accepted with old "a" value
/*
#[test]
fn test_double_point() {
    let p = ([
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ], [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ]);
    let p0 = Secpk1Fq::from_le_bytes(to_u8_arr(p.0));
    let p1 = Secpk1Fq::from_le_bytes(to_u8_arr(p.1));

    let actual_p = double_point(p0, p1);
    let res_x = [
        231, 131, 30, 231, 238, 148, 187, 95,
        146, 139, 215, 193, 70, 107, 48, 218,
        13, 139, 146, 202, 236, 105, 150, 250,
        95, 217, 187, 89, 81, 128, 177, 153
    ];
    let res_y = [
        145, 48, 60, 210, 6, 177, 60, 121,
        173, 216, 109, 9, 44, 89, 194, 160,
        132, 170, 83, 90, 247, 0, 135, 161,
        210, 218, 124, 173, 213, 210, 55, 60
    ];
    assert(to_u8_32(actual_p.0.to_le_bytes()) == res_x);
    assert(to_u8_32(actual_p.1.to_le_bytes()) == res_y);
}

#[test]
fn point_mul_with_scalar() {
    let p = ([
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ], [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ]);
    let scalar = [
        179, 23, 247, 231, 232, 159, 145, 18,
        240, 65, 170, 20, 99, 215, 45, 86,
        92, 69, 113, 200, 226, 110, 35, 191,
        20, 83, 13, 103, 83, 206, 7, 203
    ];

    let actual_p = PointMul(scalar, p);
    let expected_p = ([
        99, 60, 19, 110, 32, 60, 88, 6,
        195, 13, 208, 117, 47, 134, 184, 6,
        20, 184, 126, 29, 164, 68, 194, 188,
        117, 56, 61, 123, 170, 177, 126, 7
    ], [
        102, 27, 245, 150, 243, 148, 53, 120,
        113, 188, 20, 80, 101, 86, 84, 217,
        137, 144, 38, 207, 198, 253, 122, 190,
        231, 215, 216, 152, 171, 212, 221, 161
    ]);
    assert(actual_p == expected_p);
}
*/
