type Point = (Field, Field);
mod hash_to_curve;

pub fn main() {
    let msg = "abc";
    let _p = hash_to_curve::hash_to_curve(msg.as_bytes());
    
    // println(p.0);
    // println(p.1);
}