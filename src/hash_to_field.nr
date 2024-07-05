use crate::expand_message_xmd;

fn hash_to_field<N>(msg: [u8; N]) -> Field {
    let expand_message_xmd = expand_message_xmd::ExpandMessageXmd(msg);
    0
}
