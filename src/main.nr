mod constants;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;

pub fn main(msg: [u8; constants::MSG_LEN]) {
    let _p = hash_to_curve::hash_to_curve(msg);
    // println(p.0);
    // println(p.1);
}
