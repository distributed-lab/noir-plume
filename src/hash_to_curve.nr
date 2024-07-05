use crate::hash_to_field;
type Point = (Field, Field);

pub fn hash_to_curve<N>(msg: [u8; N]) -> Point {
    // here input some unknown number arrays

    // Step 1: u = hash_to_field(msg)
    let h2f = hash_to_field::hash_to_field(msg);
    (0, 0)
}
