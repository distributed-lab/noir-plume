pub fn plume<N>(msg: [u8; N], c: [u8; 32], s: [u8; 32], pk: [u8; 32], nullifier: [u8; 32]) {}

// Return values - r_point, hashed_to_curve_r, hashed_to_curve
fn check_ec_equations(
    c: [u8; 32],
    s: [u8; 32],
    pk: [u8; 32],
    nullifier: [u8; 32]
) -> ([u8; 32], [u8; 32], [u8; 32]) {}
