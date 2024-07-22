use dep::std::bigint::Secpk1Fq;
use dep::std::sha256::sha256_var;

use crate::utils::{to_u8_arr, to_u8_32, mod_mul_inv};
use crate::constants::{Gx, Gy, PLUME_MSG_LEN};
use crate::ec_ops::{Point, PointMul, PointAdd};
use crate::hash_to_curve::HashToCurve;

// assert at the end
pub fn plume_v1<N>(msg: [u8; N], c: [u8; 32], s: [u8; 32], pk: Point, nullifier: Point) -> [u8; 32] {
    let (_r_point, _hashed_to_curve_r, _hashed_to_curve) = check_ec_equations(msg, c, s, pk, nullifier);
    // r*G - r_point
    // r*h - hashed_to_curve_r
    // sha256(G || Pk || H || N || r*G || r*H)
    // assert c and sha256 output

    ([0 as u8; 32])
}

// Return values - r_point, hashed_to_curve_r, hashed_to_curve
fn check_ec_equations<N>(
    msg: [u8; N],
    c: [u8; 32],
    s: [u8; 32],
    pk: Point,
    nullifier: Point
) -> ([u8; 32], [u8; 32], [u8; 32]) {
    // ECDSAPrivToPub
    let G = (Gx, Gy);
    let s_point = PointMul(s, G);

    // (a / b) ^ c
    let r_point_comp = a_div_b_pow_c(s_point, pk, c);

    let mut plume_msg = [0; PLUME_MSG_LEN];
    let pk_compress = compress_ec_point(pk);
    let hash_to_curve = HashToCurve(plume_msg);

    for i in 0..N {
        plume_msg[i] = msg[i];
    }
    for i in 0..33 {
        plume_msg[N + i] = pk_compress[i];
    }

    let h_pow_s = PointMul(s, hash_to_curve);
    let hashed_to_curve_r_comp = a_div_b_pow_c(h_pow_s, nullifier, c);

    ([0 as u8; 32], [0 as u8; 32], [0 as u8; 32])
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
