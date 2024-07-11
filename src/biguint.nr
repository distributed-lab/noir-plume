use dep::std::wrapping_sub;

// Must be divisible by 4, for word, i.e. u32 type
global NUM_BYTES: u64 = 48;


fn utils_adc(a: u8, b: u8, carry: u8) -> (u8, u8) {
    let ret = a as Field + b as Field + carry as Field;
    (ret as u8, (ret as u16 >> 8) as u8)
}

fn utils_sbb(a: u8, b: u8, borrow: u8) -> (u8, u8) {
    // 7 = number of bits -1
    let ret = wrapping_sub(a as u16, b as u16 + (borrow as u16 >> 7));
    (ret as u8, (ret >> 8) as u8)
}

// Compute a + (b * c) + carry. Return (res, new_carry)
fn utils_mac(a: u8, b: u8, c: u8, carry: u8) -> (u8, u8) {
    let ret = (a as Field) + (b as Field) * (c as Field) + (carry as Field);
    (ret as u8, (ret as u16 >> 8) as u8)
}


struct BigUint {
    bytes: [u8; NUM_BYTES],
}

impl BigUint {
    pub fn zero() -> Self {
        Self { bytes: [0 as u8; NUM_BYTES] }
    }

    pub fn one() -> Self {
        let mut one = BigUint::zero();
        one.bytes[0] = 1;
        one
    }

    pub fn from_bytes(bytes: [u8]) -> Self {
        assert(bytes.len() <= NUM_BYTES as u64);
        
        let mut res = BigUint::zero();
        for i in 0..bytes.len() {
            res.bytes[i] = bytes[i];
        }
        res
    }

    pub fn from_bytes_32(bytes: [u8; 32]) -> Self {
        let mut res = BigUint::zero();
        for i in 0..32 {
            res.bytes[i] = bytes[i];
        }
        res
    }
    
    pub fn to_bytes(self: Self) -> [u8; NUM_BYTES] {
        self.bytes
    }

    pub fn to_bytes_32(self: Self) -> [u8; 32] {
        let mut bytes = [0 as u8; 32];
        for i in 0..32 {
            bytes[i] = self.bytes[i];
        }
        bytes
    }

    fn adc(self: Self, other: Self) -> (Self, u8) {
        let mut res = BigUint::zero();
        let mut carry = 0 as u8;

        for i in 0..NUM_BYTES {
            let (sum, new_carry) = utils_adc(self.bytes[i], other.bytes[i], carry);
            res.bytes[i] = sum;
            carry = new_carry;
        }

        (res, carry)
    }

    pub fn add(self: Self, other: Self) -> Self {
        let (res, _carry) = self.adc(other);
        res
    }

    fn sbb(self: Self, other: Self) -> (Self, u8) {
        let mut res = BigUint::zero();
        let mut borrow = 0 as u8;

        for i in 0..NUM_BYTES {
            let (diff, new_borrow) = utils_sbb(self.bytes[i], other.bytes[i], borrow);
            res.bytes[i] = diff;
            borrow = new_borrow;
        }
        (res, borrow)
    }

    pub fn sub(self: Self, other: Self) -> Self {
        let (res, _borrow) = self.sbb(other);
        res
    }

    // low, high result
    pub fn mul(self: Self, other: Self) -> (Self, Self) {
        let mut lo = BigUint::zero();
        let mut hi = BigUint::zero();

        for i in 0..NUM_BYTES {
            let mut carry = 0 as u8;

            for j in 0..NUM_BYTES {
                let k = i + j;

                if k >= NUM_BYTES {
                    let (n, c) = utils_mac(hi.bytes[k - NUM_BYTES], self.bytes[i], other.bytes[j], carry);
                    hi.bytes[k - NUM_BYTES] = n;
                    carry = c;
                } else {
                    let (n, c) = utils_mac(lo.bytes[k], self.bytes[i], other.bytes[j], carry);
                    lo.bytes[k] = n;
                    carry = c;
                }
            }
            hi.bytes[i] = carry;
        }
        (lo, hi)
    }

    // most significant bit
    pub fn msb(self: Self) -> u64 {
        let mut res = 0;

        for i in 0..NUM_BYTES {
            let bits = (self.bytes[i] as Field).to_le_bits(8);
            for j in 0..8 {
                if bits[j] == 1 {
                    res = i*8 + j + 1;
                }
            }
        }
        res
    }

    // Shift by 0 <= n < 8 bits
    fn shl_byte(self: Self, n: u8) -> (Self, u8) {
        assert(n < 8);

        let mut res = self;
        
        let rshift = 8 - n;
        let carry = if (n == 0) {
            0
        } else {
            self.bytes[NUM_BYTES - 1] >> rshift
        };

        if (n > 0) {
            res.bytes[0] = self.bytes[0] << n;
            for i in 1..NUM_BYTES {
                res.bytes[i] = (self.bytes[i] << n) | (self.bytes[i - 1] >> rshift);
            }
        }
        (res, carry)
    }

    // Simplify shl_byte function
    fn shl1(self: Self) -> Self {
        let mut res = self;
        let rshift = 7; // 8 - 1

        res.bytes[0] = self.bytes[0] << 1;
        for i in 1..NUM_BYTES {
            res.bytes[i] = {self.bytes[i] << 1} | (self.bytes[i - 1] >> rshift);
        }
        res
    }

    // Shift Left by n bits
    pub fn shl(self: Self, n: u64) -> Self {
        let mut res = BigUint::zero();

        if n < NUM_BYTES * 8 {
            let shift_num = n / 8;
            let rem = n % 8;

            for i in 0..NUM_BYTES {
                if i >= shift_num {
                    res.bytes[i] = self.bytes[i as u64 - shift_num];
                }
            }

            let (new_lower, _carry) = res.shl_byte(rem as u8);
            res = new_lower;
        }
        res
    }

    fn shr1(self: Self) -> Self {
        let mut res = self;
        let lshift = 7; // 8 - 1

        for i in 0..NUM_BYTES-1 {
            res.bytes[i] = (self.bytes[i] >> 1) | (self.bytes[i + 1] << lshift);
        }
        res.bytes[NUM_BYTES - 1] = self.bytes[NUM_BYTES - 1] >> 1;
        res
    }

    // quotient, remainder
    pub fn div(self: Self, other: Self) -> (Self, Self) {
        assert(!BigUint::zero().eq(other));

        if self.lt(other) {
            (BigUint::zero(), self)
        } else {
            let mut rem = self;
            let mut quo = BigUint::zero();

            let bit_diff = self.msb() - other.msb();
            let mut c = other.shl(bit_diff);

            for i in 0..(NUM_BYTES*8 + 1) {
                if i <= bit_diff {
                    if rem.lt(c) {
                        quo = quo.shl1();
                    } else {
                        rem = rem.sub(c);
                        quo = quo.shl1().add(BigUint::one());
                    }
                    c = c.shr1();
                }
            }
            (quo, rem)
        }
    }

    pub fn eq(self: Self, other: Self) -> bool {
        let mut is_eq = true;
        for i in 0..NUM_BYTES {
            is_eq = is_eq & (self.bytes[i] == other.bytes[i]);
        }
        is_eq
    }

    pub fn gt(self: Self, other: Self) -> bool {
        let (diff, borrow) = self.sbb(other);
        (borrow == 0) & !diff.eq(BigUint::zero())
    }

    pub fn lt(self: Self, other: Self) -> bool {
        other.gt(self)
    }
}


// Tests
#[test]
fn test_from_bytes1() {
    // let bytes = [2 as u8];
    let a = BigUint::from_bytes(&[2]);

    assert(
        a.eq(
            BigUint {
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
    let a = BigUint::from_bytes(&[0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    assert(
        a.eq(
            BigUint {
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
    let a = BigUint::zero();
    let b = BigUint::one();

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
fn test_mul1() {
    let a = BigUint::from_bytes(&[2]);
    let b = BigUint::from_bytes(&[3]);
    let (lo, hi) = a.mul(b);
    
    assert(lo.eq(BigUint::from_bytes(&[6])));
    assert(hi.eq(BigUint::zero()));
}

#[test]
fn test_mul2() {
    let a = BigUint { bytes: [0xff; NUM_BYTES] };
    let b = a;
    let (lo, hi) = a.mul(b);

    let mut hi_expect = [0xff; NUM_BYTES];
    hi_expect[0] = 0xfe;
    let hi_expect = BigUint { bytes: hi_expect };

    assert(lo.eq(BigUint::one()));
    assert(hi.eq(hi_expect));
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
