mod constants;
mod hash_to_curve;
mod hash_to_field;
mod expand_message_xmd;
mod biguint;

pub fn main(msg: [u8; constants::MSG_LEN]) {
    let _p = hash_to_curve::hash_to_curve(msg);
    // println(p.0);
    // println(p.1);
}

// Tests
use crate::biguint::BigUint;
use crate::biguint::NUM_BYTES;

#[test]
fn test_from_bytes1() {
    // let bytes = [2 as u8];
    let a = BigUint::from_bytes(&[2]);

    assert(
        a.eq(
            biguint::BigUint {
        bytes: [
            2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ]
    }
        )
    );
}

#[test]
fn test_from_bytes2() {
    // 7 bytes of 0xff
    let a = biguint::BigUint::from_bytes(&[0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    assert(
        a.eq(
            biguint::BigUint {
        bytes: [
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ]
    }
        )
    );
}

#[test]
fn test_to_bytes1() {
    let a = biguint::BigUint::zero();
    let b = biguint::BigUint::one();

    let c = a.sub(b);
    assert(c.to_bytes() == [0xff; NUM_BYTES]);
}

#[test]
fn test_add1() {
    let a = BigUint::from_bytes(&[1]);
    let b = BigUint::from_bytes(&[2]);
    let sum = a.add(b);

    assert(sum.eq(BigUint::from_bytes(&[3])));
}

#[test]
fn test_add2() {
    let a = BigUint::from_bytes(&[0xff, 0xff, 0xff, 0xff, 0]);
    let b = BigUint::from_bytes(&[1, 0, 0, 0, 0]);
    let sum = a.add(b);

    assert(sum.eq(BigUint::from_bytes(&[0, 0, 0, 0, 1])));
}

#[test]
fn test_adc1() {
    let a = BigUint { bytes: [0xff; NUM_BYTES] };
    let b = BigUint::one();
    let (sum, carry) = a.adc(b);

    assert(sum.eq(BigUint::zero()));
    assert(carry == 1);
}

#[test]
fn test_sub1() {
    let a = BigUint::from_bytes(&[5]);
    let b = BigUint::from_bytes(&[3]);
    let diff = a.sub(b);

    assert(diff.eq(BigUint::from_bytes(&[2])));
}

// Maybe bad test
#[test]
fn test_sub2() {
    let a = BigUint::from_bytes(&[1, 2, 0, 0, 0]);
    let b = BigUint::from_bytes(&[2, 0, 0, 0, 0]);
    let diff = a.sub(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff, 1])));
}

// Maybe bad test
#[test]
fn test_sbb1() {
    let a = BigUint::from_bytes(&[1, 0, 0, 0, 0]);
    let b = BigUint::from_bytes(&[2, 0, 0, 0, 0]);
    let (diff, borrow) = a.sbb(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff; NUM_BYTES])));
    assert(borrow >> 7 == 1); // 7 = number of bits
}

#[test]
fn test_cmp1() {
    let a = BigUint::from_bytes(&[2, 0]);
    let b = BigUint::from_bytes(&[0, 2]);

    assert(!a.eq(b));

    assert(a.lt(b));
    assert(!a.gt(b));
}

#[test]
fn test_cmp2() {
    let a = BigUint::from_bytes(&[0, 2]);
    let b = BigUint::from_bytes(&[0, 2]);

    assert(a.eq(b));

    assert(!a.lt(b));
    assert(!a.gt(b));
}

#[test]
fn test_shl1() {
    let a = BigUint::from_bytes(&[1, 2]);
    let b = a.shl(0);

    assert(a.eq(b));
}

#[test]
fn test_shl2() {
    let a = BigUint::from_bytes(&[1, 2]);
    let b = a.shl(NUM_BYTES * 8);

    assert(b.eq(BigUint::zero()));
}

#[test]
fn test_shl3() {
    let a = BigUint::from_bytes(&[1, 2]);
    let b = a.shl(1);

    let bytes = b.to_bytes();

    let mut expected = [0 as u8; NUM_BYTES];
    expected[0] = 2;
    expected[1] = 4;

    assert(bytes == expected);
}

#[test]
fn test_shl4() {
    let a = BigUint::from_bytes(&[1, 2]);
    let b = a.shl(8);

    assert(b.eq(BigUint::from_bytes(&[0, 1, 2])));
}

#[test]
fn test_shl5() {
    let a = BigUint::from_bytes(&[1]);
    let b = a.shl1();

    assert(b.eq(BigUint::from_bytes(&[2])));
}

#[test]
fn test_shl6() {
    let a = BigUint::from_bytes(&[0x80]);
    let b = a.shl1();

    assert(b.eq(BigUint::from_bytes(&[0, 1])));
}

#[test]
fn test_shr() {
    let a = BigUint::from_bytes(&[2, 4]);
    let b = a.shr1();

    let bytes = b.to_bytes();

    let mut expected = [0 as u8; NUM_BYTES];
    expected[0] = 1;
    expected[1] = 2;

    assert(bytes == expected);
}

#[test]
fn test_msb1() {
    let a = BigUint::from_bytes(&[0]);
    let b = a.msb();

    assert(b == 0);
}

#[test]
fn test_msb2() {
    let a = BigUint::from_bytes(&[1]);
    let b = a.msb();

    assert(b == 1);
}

#[test]
fn test_msb3() {
    let a = BigUint::from_bytes(&[0xff]);
    let b = a.msb();

    assert(b == 8);
}

#[test]
fn test_msb4() {
    let a = BigUint::from_bytes(&[1, 5]);
    let b = a.msb();

    assert(b == 11);
}

#[test]
fn test_div1() {
    let a = BigUint::from_bytes(&[7]);
    let b = BigUint::from_bytes(&[3]);

    let (q, r) = a.div(b);

    assert(q.eq(BigUint::from_bytes(&[2])));
    assert(r.eq(BigUint::from_bytes(&[1])));
}

#[test]
fn test_div2() {
    // 7 + 256*2 + 256*256*3
    let a = BigUint::from_bytes(&[7, 2, 3]);
    let b = BigUint::from_bytes(&[7, 2, 3]);

    let (q, r) = a.div(b);

    assert(q.eq(BigUint::one()));
    assert(r.eq(BigUint::zero()));
}

// Failed
#[test]
fn test_div3() {
    // (256*256 + 2)/256 = (256, 2)
    let a = BigUint::from_bytes(&[2, 0, 1]);
    let b = BigUint::from_bytes(&[0, 1]);

    let (q, r) = a.div(b);

    assert(q.eq(BigUint::from_bytes(&[0, 1])));
    assert(r.eq(BigUint::from_bytes(&[2])));
}

#[test]
fn test_div4() {
    let a = BigUint::from_bytes(&[7]);
    let b = BigUint::from_bytes(&[1]);

    let (q, r) = a.div(b);

    assert(q.eq(BigUint::from_bytes(&[7])));
    assert(r.eq(BigUint::from_bytes(&[0])));
}

#[test]
fn test_div5() {
    // 7 + 256*2 + 256*256*3
    let a = BigUint::from_bytes(&[7, 2, 3]);
    let b = BigUint::from_bytes(&[0, 0, 0, 1]);

    let (q, r) = a.div(b);

    assert(q.eq(BigUint::zero()));
    assert(r.eq(BigUint::from_bytes(&[7, 2, 3])));
}
