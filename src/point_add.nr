use dep::std::bigint::Secpk1Fq;
use crate::utils::{to_u8_arr, to_u8_32};

// https://www.rareskills.io/post/elliptic-curve-addition
pub fn PointAdd(x0: [u8; 32], y0: [u8; 32], x1: [u8; 32], y1: [u8; 32]) -> ([u8; 32], [u8; 32]) {
    let x0 = Secpk1Fq::from_le_bytes(to_u8_arr(x0));
    let y0 = Secpk1Fq::from_le_bytes(to_u8_arr(y0));
    let x1 = Secpk1Fq::from_le_bytes(to_u8_arr(x1));
    let y1 = Secpk1Fq::from_le_bytes(to_u8_arr(y1));

    let lambda = (y1 - y0) / (x1 - x0);
    let x2 = (lambda * lambda - x0 - x1);
    let y2 = (lambda * (x0 - x2) - y0).to_le_bytes();
    (to_u8_32(x2.to_le_bytes()), to_u8_32(y2))
}

#[test]
fn test_point_add_with_msg_abc() {
    let p0_x = [
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ];
    let p0_y = [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ];

    let p1_x = [
        120, 31, 50, 101, 252, 100, 135, 184,
        30, 73, 248, 5, 172, 141, 107, 4,
        130, 39, 24, 108, 224, 81, 231, 221,
        119, 78, 93, 209, 148, 151, 239, 233
    ];
    let p1_y = [
        179, 23, 247, 231, 232, 159, 145, 18,
        240, 65, 170, 20, 99, 215, 45, 86,
        92, 69, 113, 200, 226, 110, 35, 191,
        20, 83, 13, 103, 83, 206, 7, 203
    ];

    let (actual_px, actual_py) = PointAdd(p0_x, p0_y, p1_x, p1_y);
    let expected_px = [
        75, 44, 203, 179, 31, 241, 159, 189,
        96, 87, 32, 249, 249, 236, 182, 114,
        238, 108, 12, 18, 147, 34, 81, 107,
        41, 219, 66, 171, 30, 224, 119, 51
    ];
    let expected_py = [
        246, 113, 131, 156, 123, 108, 124, 72,
        141, 104, 148, 111, 17, 182, 15, 144,
        224, 190, 177, 1, 42, 56, 77, 4,
        209, 235, 239, 51, 15, 137, 149, 127
    ];

    assert(actual_px == expected_px);
    assert(actual_py == expected_py);
}
