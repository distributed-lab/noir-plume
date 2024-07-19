mod constants;
mod biguint;
mod utils;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod map_to_curve;
mod iso_map;
mod ec_ops;
mod plume;

pub fn main(
    msg: [u8; constants::MSG_LEN],
    c: [u8; 32],
    s: [u8; 32],
    pk: [[u8; 32]; 2],
    nullifier: [u8; 32]
) {
    plume::plume_v1(msg, c, s, (pk[0], pk[1]), nullifier);
    // TODO: delete later
    /*
    let (x, y) = hash_to_curve::hash_to_curve(msg);

    print("x_le_bytes = ");
    println(x);

    print("y_le_bytes = ");
    println(y);
    */
}
