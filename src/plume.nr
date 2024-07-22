use dep::std::bigint::Secpk1Fq;
use dep::std::sha256::sha256_var;

use crate::utils::{to_u8_arr, to_u8_32, mod_mul_inv};
use crate::constants::{Gx, Gy, PLUME_MSG_LEN};
use crate::ec_ops::{Point, PointMul, PointAdd};
use crate::hash_to_curve::HashToCurve;

// assert at the end
pub fn plume_v1<N>(msg: [u8; N], c: [u8; 32], s: [u8; 32], pk: Point, nullifier: Point) -> [u8; 32] {
    let (r_point, hashed_to_curve_r, hashed_to_curve) = check_ec_equations(msg, c, s, pk, nullifier);
    // r*G - r_point
    // r*h - hashed_to_curve_r
    // sha256(G || Pk || H || N || r*G || r*H)
    // assert c and sha256 output
    sha256_12_coordinates(pk, hashed_to_curve, nullifier, r_point, hashed_to_curve_r)
    //([0 as u8; 32])
}

// Return values - r_point, hashed_to_curve_r, hashed_to_curve
fn check_ec_equations<N>(
    msg: [u8; N],
    c: [u8; 32],
    s: [u8; 32],
    pk: Point,
    nullifier: Point
) -> (Point, Point, Point) {
    // ECDSAPrivToPub
    let G = (Gx, Gy);
    let s_point = PointMul(s, G);

    // (a / b) ^ c
    let r_point = a_div_b_pow_c(s_point, pk, c);

    let mut plume_msg = [0; PLUME_MSG_LEN];
    let pk_compress = compress_ec_point(pk);
    let hashed_to_curve = HashToCurve(plume_msg);

    for i in 0..N {
        plume_msg[i] = msg[i];
    }
    for i in 0..33 {
        plume_msg[N + i] = pk_compress[i];
    }

    let h_pow_s = PointMul(s, hashed_to_curve);
    let hashed_to_curve_r = a_div_b_pow_c(h_pow_s, nullifier, c);
    (r_point, hashed_to_curve_r, hashed_to_curve)
}

fn a_div_b_pow_c(a: Point, b: Point, c: [u8; 32]) -> Point {
    let b_pow_c = PointMul(c, b);
    let y = Secpk1Fq::from_le_bytes(to_u8_arr(b_pow_c.1));
    PointAdd(a, (b_pow_c.0, to_u8_32((y - y - y).to_le_bytes())))
}

// Warn! Not tested!
// In circom code Point is [u64; 4].
// Link to the code line https://github.com/plume-sig/zk-nullifier-sig/blob/92315e24f4f67535fe590b86eed8955dee1dc07e/circuits/circom/verify_nullifier.circom#L325
fn compress_ec_point(pk: Point) -> [u8; 33] {
    let mut compressed = [0 as u8; 33];
    compressed[0] = (pk.1[0] & 1) + 2;

    // TODO: Possibly without reverse bits
    for i in 0..32 {
        compressed[32-i] = pk.0[i];
    }
    compressed
}

fn sha256_12_coordinates(pk: Point, h: Point, nullifier: Point, gr: Point, hr: Point) -> [u8; 32] {
    let mut compressed = [[0 as u8; 33]; 6];
    compressed[0] = compress_ec_point((get_gx(), get_gy()));
    compressed[1] = compress_ec_point(pk);
    compressed[2] = compress_ec_point(h);
    compressed[3] = compress_ec_point(nullifier);
    compressed[4] = compress_ec_point(gr);
    compressed[5] = compress_ec_point(hr);

    // msg_bits = 6*33*8
    // total_bits = (msg_bits // 512) * 512
    // msg_bits % 512 != 0, then total_bits += 512
    let mut msg = [0 as u1; 2048];
    for i in 0..6 {
        for j in 0..33 {
            let byte = (compressed[i][j] as Field).to_le_bits(8);

            for k in 0..8 {
                msg[i*j*8 + j*8 + k] = byte[k];
            }
        }
    }

    // total bytes = 2048/8
    let mut res = [0 as u8; 256];
    for i in 0..2048 - 64 {
        let ind = (i as u16) / 8;
        let shift = (i as u16) % 8;

        if (i == 1584) {
            res[ind] |= (1 << shift as u8);
        } else {
            res[ind] |= (msg[i] as u8 << shift as u8);
        }
    }

    // The last 8 bytes are filled with the length of msg_bits
    // msg_bis in bytes = [48, 6]
    res[256-8] = 48;
    res[256-7] = 6;
    sha256_var(res, res.len())
}

fn get_gx() -> [u8; 32] {
    [
        152, 23, 248, 22, 91, 129, 242, 89,
        217, 40, 206, 45, 219, 252, 155, 2,
        7, 11, 135, 206, 149, 98, 160, 85,
        172, 187, 220, 249, 126, 102, 190, 121
    ]
}

fn get_gy() -> [u8; 32] {
    [
        184, 212, 16, 251, 143, 208, 71, 156,
        25, 84, 133, 166, 72, 180, 23, 253,
        168, 8, 17, 14, 252, 251, 164, 93,
        101, 196, 163, 38, 119, 218, 58, 72
    ]
}

#[test]
fn test_plume_v1() {
    // Maybe another message
    let msg = [97, 98, 99];
    let H = ([
        101, 11, 128, 176, 13, 25, 162, 54, 17, 77, 197, 73, 188, 255, 42, 31, 192, 205, 171, 149, 147, 136, 24, 194, 35, 159, 103, 18, 14, 45, 172, 188
    ], [
        110, 150, 112, 205, 240, 135, 93, 20, 82, 55, 43, 227, 83, 26, 169, 176, 35, 161, 144, 31, 8, 72, 211, 87, 231, 192, 116, 201, 57, 179, 207, 59
    ]);
    let s = [
        202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230
    ];
    let c = [
        84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198
    ];
    let sk = [
        81, 155, 66, 61, 113, 95, 139, 88, 31, 79, 168, 238, 89, 244, 119, 26, 91, 68, 200, 19, 11, 78, 62, 172, 202, 84, 165, 109, 218, 114, 180, 100
    ];
    
    let pk = PointMul(sk, (get_gx(), get_gy()));
    let nullifier = PointMul(sk, H);

    let actual_c = plume_v1(msg, c, s, pk, nullifier);
    assert(actual_c == c);
}
