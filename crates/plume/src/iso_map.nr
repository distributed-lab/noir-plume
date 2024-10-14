use bignum::BigNum;
use crate::constants::Fq;
use crate::ec_ops::Point;

/*
k_(1,3) * x^3 + 
k_(1,2) * x^2 + 
k_(1,1) * x   +
k_(1,0)
*/
fn x_num(x: Fq, x_2: Fq, x_3: Fq) -> Fq {
    let k1_0 = BigNum::from_array(k_1_0());
    let k1_1 = BigNum::from_array(k_1_1());
    let k1_2 = BigNum::from_array(k_1_2());
    let k1_3 = BigNum::from_array(k_1_3());
    k1_0 + k1_1 * x + k1_2 * x_2 + k1_3 * x_3
}

/*
x'^2 +
k_(2,1) * x' +
k_(2,0)
*/
fn x_den(x: Fq, x_2: Fq) -> Fq {
    let k2_0 = BigNum::from_array(k_2_0());
    let k2_1 = BigNum::from_array(k_2_1());
    x_2 + k2_1 * x + k2_0
}

/*
k_(3,3) * x'^3 +
k_(3,2) * x'^2 +
k_(3,1) * x' +
k_(3,0)
*/
fn y_num(x: Fq, x_2: Fq, x_3: Fq) -> Fq {
    let k3_0 = BigNum::from_array(k_3_0());
    let k3_1 = BigNum::from_array(k_3_1());
    let k3_2 = BigNum::from_array(k_3_2());
    let k3_3 = BigNum::from_array(k_3_3());
    k3_0 + k3_1 * x + k3_2 * x_2 + k3_3 * x_3
}

/*
x'^3 +
k_(4,2) * x'^2 +
k_(4,1) * x' +
k_(4,0)
*/
fn y_den(x: Fq, x_2: Fq, x_3: Fq) -> Fq {
    let k4_0 = BigNum::from_array(k_4_0());
    let k4_1 = BigNum::from_array(k_4_1());
    let k4_2 = BigNum::from_array(k_4_2());
    k4_0 + k4_1 * x + k4_2 * x_2 + x_3
}

// https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#name-3-isogeny-map-for-secp256k1
pub fn iso_map(p: Point) -> Point {
    let (x, y) = p;

    // Step 1. Calculate x^2
    // Step 2. Calculate x^3
    let x_2 = x * x;
    let x_3 = x_2 * x;

    let x_num = x_num(x, x_2, x_3);
    let x_den = x_den(x, x_2);
    let y_num = y_num(x, x_2, x_3);
    let y_den = y_den(x, x_2, x_3);

    let x = (x_num / x_den);
    let y = (y * y_num / y_den);
    (x, y)
}

#[test]
fn test_iso_map() {
    let p = (BigNum::from_array([0xf7ae5f23c431edeb6be5bb360925ea, 0xce532d92416a9488104157036455a0, 0x8dec]), BigNum::from_array([0x13d22e4d45e5bef361e486c6a5da4a, 0xae1c326847bd4a133e5dee6b2ca67c, 0xe249]));
    let actual_p = iso_map(p);
    let expected_p = (BigNum::from_array([0x7c2a947a20fd9ad71039f8b0e29ff8, 0x6d261a5e00fe5cf45e827b507643e6, 0xf89d]), BigNum::from_array([0x1ce936d563bc1cee1dcffc806caf57, 0x55e0cc34a9176ead91c6c3acb1aacb, 0xb338]));
    assert(actual_p == expected_p);
}

// Constants
fn k_1_0() -> [Field; 3] {
    [ 0xe38e38e38e38e38e38e38daaaaa8c7, 0xe38e38e38e38e38e38e38e38e38e38, 0x8e38 ]
}
fn k_1_1() -> [Field; 3] {
    [ 0x95d2fc0bf63b92dfff1044f17c6581, 0xd4c80bc321d5b9f315cea7fd44c5d5, 0x7d3 ]
}
fn k_1_2() -> [Field; 3] {
    [ 0x506144037c40314ecbd0b53d9dd262, 0x328d23f234e6e2a413deca25caece4, 0x534c ]
}
fn k_1_3() -> [Field; 3] {
    [ 0xe38e38e38e38e38e38e38daaaaa88c, 0xe38e38e38e38e38e38e38e38e38e38, 0x8e38 ]
}

fn k_2_0() -> [Field; 3] {
    [ 0xcd409542f8487d9fe6b745781eb49b, 0x71193d94918a9ca34ccbb7b640dd86, 0xd357 ]
}
fn k_2_1() -> [Field; 3] {
    [ 0xd36b641f5e41bbc52a56612a8c6d14, 0xc6f64383dc1df7c4b2d51b54225406, 0xedad ]
}

fn k_3_0() -> [Field; 3] {
    [ 0x684bda12f684bda12f684b8e38e23c, 0x12f684bda12f684bda12f684bda12f, 0x4bda ]
}
fn k_3_1() -> [Field; 3] {
    [ 0x7ab046d686da6fdffc90fc201d71a3, 0xc32d5cb7c0fa9d0a54b12a0a6d564, 0xc75e ]
}
fn k_3_2() -> [Field; 3] {
    [ 0x2830a201be2018a765e85a9ecee931, 0x194691f91a73715209ef6512e57672, 0x29a6 ]
}
fn k_3_3() -> [Field; 3] {
    [ 0xa12f684bda12f684bda12f38e38d84, 0x4bda12f684bda12f684bda12f684bd, 0x2f68 ]
}

fn k_4_0() -> [Field; 3] {
    [ 0xfffffffffffffffffffffefffff93b, 0xffffffffffffffffffffffffffffff, 0xffff ]
}
fn k_4_1() -> [Field; 3] {
    [ 0x67c1bfc8e8d978dfb425d2685c2573, 0x534bb8bdb49fd5e9e6632722c29894, 0x7a06 ]
}
fn k_4_2() -> [Field; 3] {
    [ 0x3d21162f0d6299a7bf8192bfd2a76f, 0xaa716545ca2cf3a70c3fa8fe337e0a, 0x6484 ]
}
