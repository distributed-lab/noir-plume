mod constants;
mod biguint;
mod utils;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod map_to_curve;
mod iso_map;
mod point_add;

pub fn main(msg: [u8; constants::MSG_LEN]) {
    let (x, y) = hash_to_curve::hash_to_curve(msg);

    print("x_le_bytes = ");
    println(x);

    print("y_le_bytes = ");
    println(y);
}
