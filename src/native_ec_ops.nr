use std::bigint::Secpk1Fq;
global ZERO = Secpk1Fq::from_le_bytes(&[0]);

type Point = (Secpk1Fq, Secpk1Fq);

// Operations taken from the http://delta.cs.cinvestav.mx/~francisco/cripto/ellipticbg.pdf doc
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
    let two = Secpk1Fq::from_le_bytes(&[2]);
    let three = Secpk1Fq::from_le_bytes(&[3]);

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

pub fn test_point_mul() {
    let p = (Secpk1Fq::from_le_bytes(
            &[
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]
        ));
    let scalar = [
        100, 180, 114, 218, 109, 165, 84, 202, 172, 62, 78, 11, 19, 200, 68, 91, 26, 119, 244, 89, 238, 168, 79, 31, 88, 139, 95, 113, 61, 66, 155, 81
    ];

    let actual_p = point_mul(scalar, p);
    let expected_p = (Secpk1Fq::from_le_bytes(
            &[
        48, 88, 229, 103, 12, 29, 111, 98, 30, 92, 164, 115, 100, 166, 197, 252, 69, 231, 204, 194, 224, 185, 228, 221, 138, 239, 114, 129, 210, 62, 188, 87
    ]
        ), Secpk1Fq::from_le_bytes(
            &[
        115, 203, 158, 229, 127, 8, 214, 145, 168, 143, 163, 126, 230, 58, 159, 159, 96, 17, 225, 136, 33, 221, 110, 228, 58, 243, 88, 141, 72, 65, 47, 106
    ]
        ));
    assert(actual_p == expected_p);
}
