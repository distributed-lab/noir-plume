mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;

global PADDING_SIZE = 64 + 2 + 50 + 1;
global MSG_LEN = 3;

pub fn main(msg: [u8; MSG_LEN]) {
    let _p = hash_to_curve::hash_to_curve(msg);

    // println(p.0);
    // println(p.1);
}
