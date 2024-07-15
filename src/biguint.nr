// Based on the code https://github.com/shuklaayush/noir-bigint
use dep::std::wrapping_sub;

// Note: If you need a different number of bytes, change only this variable
global NUM_BLOCKS: u64 = 24;

// Fixed value for u32 blocks arrary,
// Can optimize to 256/8 = 16 bytes, otherwise bit shift doesn't work properly
global BYTES_PER_BLOCK: u64 = 4;

global NUM_BYTES: u64 = NUM_BLOCKS * BYTES_PER_BLOCK;
global BITS_PER_BLOCK: u64 = BYTES_PER_BLOCK * 8;


fn utils_adc(a: u32, b: u32, carry: u32) -> (u32, u32) {
    let ret = a as Field + b as Field + carry as Field;
    (ret as u32, (ret as u64 >> BITS_PER_BLOCK as u8) as u32)
}

fn utils_sbb(a: u32, b: u32, borrow: u32) -> (u32, u32) {
    // 7 = number of bits -1
    let ret = wrapping_sub(a as u64, b as u64 + (borrow as u64 >> (BITS_PER_BLOCK - 1) as u8));
    (ret as u32, (ret >> BITS_PER_BLOCK as u8) as u32)
}

// Compute a + (b * c) + carry. Return (res, new_carry)
fn utils_mac(a: u32, b: u32, c: u32, carry: u32) -> (u32, u32) {
    let ret = (a as Field) + (b as Field) * (c as Field) + (carry as Field);
    (ret as u32, (ret as u64 >> BITS_PER_BLOCK as u8) as u32)
}


struct BigUint {
    blocks: [u32; NUM_BLOCKS],
}

impl BigUint {
    pub fn zero() -> Self {
        Self { blocks: [0 as u32; NUM_BLOCKS] }
    }

    pub fn one() -> Self {
        let mut one = BigUint::zero();
        one.blocks[0] = 1;
        one
    }

    pub fn from_bytes(bytes: [u8]) -> Self {
        assert(bytes.len() <= NUM_BYTES as u64);
        
        let mut res = BigUint::zero();
        for i in 0..bytes.len() {
            let block_ind = (i as u32) / (BYTES_PER_BLOCK as u32);
            let byte_ind = (i as u32) % (BYTES_PER_BLOCK as u32);


            res.blocks[block_ind as Field] |= (bytes[i] as u32) << (byte_ind * 8) as u8;
        }
        res
    }

    pub fn from_bytes_32(bytes: [u8; 32]) -> Self {
        let mut res = BigUint::zero();
        for i in 0..32 {
            let block_ind = i / BYTES_PER_BLOCK;
            let byte_ind = i % BYTES_PER_BLOCK;

            res.blocks[block_ind] |= (bytes[i] as u32) << (byte_ind * 8) as u8;
        }
        res
    }
    
    pub fn to_bytes(self: Self) -> [u8; NUM_BYTES] {
        let mut res = [0 as u8; NUM_BYTES];

        for i in 0..NUM_BLOCKS {
            let block_bytes = (self.blocks[i] as Field).to_le_bytes(BYTES_PER_BLOCK as u32);

            for j in 0..BYTES_PER_BLOCK {
                let idx = i * BYTES_PER_BLOCK + j;
                res[idx] = block_bytes[j as Field];
            }
        }
        res
    }

    pub fn to_bytes_32(self: Self) -> [u8; 32] {
        let mut res = [0 as u8; 32];
        let blocks = 32 / BYTES_PER_BLOCK;

        for i in 0..blocks {
            let block_bytes = (self.blocks[i] as Field).to_le_bytes(BYTES_PER_BLOCK as u32);

            for j in 0..BYTES_PER_BLOCK {
                let idx = i * BYTES_PER_BLOCK + j;
                res[idx] = block_bytes[j as Field];
            }
        }
        res
    }

    fn adc(self: Self, other: Self) -> (Self, u32) {
        let mut res = BigUint::zero();
        let mut carry = 0 as u32;

        for i in 0..NUM_BLOCKS {
            let (sum, new_carry) = utils_adc(self.blocks[i], other.blocks[i], carry);
            res.blocks[i] = sum;
            carry = new_carry;
        }
        (res, carry)
    }

    pub fn add(self: Self, other: Self) -> Self {
        self.adc(other).0
    }

    fn sbb(self: Self, other: Self) -> (Self, u32) {
        let mut res = BigUint::zero();
        let mut borrow = 0 as u32;

        for i in 0..NUM_BLOCKS {
            let (diff, new_borrow) = utils_sbb(self.blocks[i], other.blocks[i], borrow);
            res.blocks[i] = diff;
            borrow = new_borrow;
        }
        (res, borrow)
    }

    pub fn sub(self: Self, other: Self) -> Self {
        self.sbb(other).0
    }

    // The result of mul function is expected to be less than NUM_BYTES
    pub fn mul(self: Self, other: Self) -> Self {
        let mut res = BigUint::zero();

        for i in 0..NUM_BLOCKS {
            let mut carry = 0 as u32;

            for j in 0..NUM_BLOCKS {
                let k = i + j;

                if k < NUM_BLOCKS {
                    let (n, c) = utils_mac(res.blocks[k], self.blocks[i], other.blocks[j], carry);
                    res.blocks[k] = n;
                    carry = c;
                }
            }
        }
        res
    }

    // low, high results
    pub fn extend_mul(self: Self, other: Self) -> (Self, Self) {
        let mut lo = BigUint::zero();
        let mut hi = BigUint::zero();

        for i in 0..NUM_BLOCKS {
            let mut carry = 0 as u32;

            for j in 0..NUM_BLOCKS {
                let k = i + j;

                if k >= NUM_BLOCKS {
                    let (n, c) = utils_mac(hi.blocks[k - NUM_BLOCKS], self.blocks[i], other.blocks[j], carry);
                    hi.blocks[k - NUM_BLOCKS] = n;
                    carry = c;
                } else {
                    let (n, c) = utils_mac(lo.blocks[k], self.blocks[i], other.blocks[j], carry);
                    lo.blocks[k] = n;
                    carry = c;
                }
            }
            hi.blocks[i] = carry;
        }
        (lo, hi)
    }

    pub fn msb(self: Self) -> u64 {
        let mut res = 0;

        for i in 0..NUM_BLOCKS {
            let bits = (self.blocks[i] as Field).to_le_bits(32);
            for j in 0..32 {
                if bits[j] == 1 {
                    res = i*32 + j + 1;
                }
            }
        }
        res
    }

    pub fn is_even(self: Self) -> bool {
        self.blocks[0] & 1 == 1
    }

    // Shift by 0 <= n < BITS_PER_BLOCK bits
    fn shl_block(self: Self, n: u8) -> (Self, u32) {
        assert(n < BITS_PER_BLOCK as u8);

        let mut res = self;
        let rshift = BITS_PER_BLOCK as u8 - n;
        let carry = if (n == 0) { 0 } else { self.blocks[NUM_BLOCKS - 1] >> rshift };

        if (n > 0) {
            res.blocks[0] = self.blocks[0] << n as u8;
            for i in 1..NUM_BLOCKS {
                res.blocks[i] = (self.blocks[i] << n) | (self.blocks[i - 1] >> rshift);
            }
        }
        (res, carry)
    }

    // Simplify shl_byte function
    fn shl1(self: Self) -> Self {
        let mut res = self;
        let rshift = (BITS_PER_BLOCK - 1) as u8;

        res.blocks[0] = self.blocks[0] << 1;
        for i in 1..NUM_BLOCKS {
            res.blocks[i] = {self.blocks[i] << 1} | (self.blocks[i - 1] >> rshift);
        }
        res
    }

    // Shift Left by n bits
    pub fn shl(self: Self, n: u64) -> Self {
        let mut res = BigUint::zero();

        if n < NUM_BYTES * 8 {
            let shift_num = n / BITS_PER_BLOCK;
            let rem = n % BITS_PER_BLOCK;

            for i in 0..NUM_BLOCKS {
                if i >= shift_num {
                    res.blocks[i] = self.blocks[i as u64 - shift_num];
                }
            }
            res = res.shl_block(rem as u8).0;
        }
        res
    }

    fn shr1(self: Self) -> Self {
        let mut res = self;
        let lshift = (BITS_PER_BLOCK - 1) as u8;

        for i in 0..NUM_BLOCKS-1 {
            res.blocks[i] = (self.blocks[i] >> 1) | (self.blocks[i + 1] << lshift);
        }
        res.blocks[NUM_BLOCKS - 1] = self.blocks[NUM_BLOCKS - 1] >> 1;
        res
    }

    // (quotient, remainder)
    pub fn div(self: Self, other: Self) -> (Self, Self) {
        assert(!BigUint::zero().eq(other));

        if self.lt(other) {
            (BigUint::zero(), self)
        } else {
            let mut rem = self;
            let mut quo = BigUint::zero();

            let bit_diff = self.msb() - other.msb();
            let mut c = other.shl(bit_diff);

            for _ in 0..bit_diff+1 {
                if rem.lt(c) {
                    quo = quo.shl1();
                } else {
                    rem = rem.sub(c);
                    quo = quo.shl1().add(BigUint::one());
                }
                c = c.shr1();
            }
            (quo, rem)
        }
    }

    /* TODO: Implement
    Use simple binary search algorithm
    The code is specialized, so here used 32*8 iterations.
    For more general code, you should replace
    the number of iterations with NUM_BYTES * 8 and use extend_mul (not necessary) instead of regular mul.
    If we have hi part, then sqrt lower than current part
    */
    pub fn sqrt(self: Self) -> Self {
        assert(BigUint::from_bytes_32([0xff; 32]).gte(self));
        let mut mid = self;

        if self.eq(BigUint::zero()) | self.eq(BigUint::one()) {
            mid
        } else {
            let mut lo = BigUint::zero();
            let mut hi = mid;
            let mut done = false;
            
            for _ in 0..self.msb() {
                if !done {
                    // shr1 replace .div(2) operation
                    mid = lo.add(hi).shr1();
                    let sq = mid.mul(mid);

                    if (sq.lt(self)) {
                        lo = mid.add(BigUint::one());
                    } else {
                        if (sq.gt(self)) {
                            hi = mid.sub(BigUint::one());
                        } else {
                            done = true;
                            lo = mid;
                        }
                    }
                }
            }
            if hi.gt(lo) { lo } else { hi }
        }
    }

    // TODO: Test method
    // No longer for BigUint, but for BigInt
    pub fn negative(self: Self) -> Self {
        let mut res = self;
        let max: u32 = 0xffffffff;

        for i in 0..NUM_BLOCKS {
            res.blocks[i] = max - res.blocks[i];
        }
        res.add(BigUint::one())
    }

    pub fn eq(self: Self, other: Self) -> bool {
        self.blocks == other.blocks
    }

    pub fn gt(self: Self, other: Self) -> bool {
        let (diff, borrow) = self.sbb(other);
        (borrow == 0) & !diff.eq(BigUint::zero())
    }

    pub fn gte(self: Self, other: Self) -> bool {
        self.sbb(other).1 == 0
    }

    pub fn lt(self: Self, other: Self) -> bool {
        other.gt(self)
    }
}


#[test]
fn test_from_bytes1() {
    let a = BigUint::from_bytes(&[2]);

    assert(
        a.eq(
            BigUint {
        blocks: [
            2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
        blocks: [
            0xffffffff, 0xffffff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ]
    }
        )
    );
}

#[test]
fn test_from_bytes_32_1() {
    let actual = BigUint::from_bytes_32([0xff; 32]);
    assert(
        actual.eq(
            BigUint {
        blocks: [
            0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
fn test_to_bytes_32_1() {
    let a = BigUint::from_bytes_32([
        0, 158, 104, 228, 242, 160, 170, 77,
        4, 139, 81, 3, 106, 231, 27, 83,
        220, 149, 200, 117, 204, 253, 208, 19,
        168, 149, 181, 163, 93, 182, 151, 88
    ]);

    let expected_bytes = [
        0, 158, 104, 228, 242, 160, 170, 77,
        4, 139, 81, 3, 106, 231, 27, 83,
        220, 149, 200, 117, 204, 253, 208, 19,
        168, 149, 181, 163, 93, 182, 151, 88
    ];
    assert(a.to_bytes_32() == expected_bytes);
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
    let a = BigUint { blocks: [0xffffffff; NUM_BLOCKS] };
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

#[test]
fn test_sub2() {
    let a = BigUint::from_bytes(&[1, 2, 0, 0, 0]);
    let b = BigUint::from_bytes(&[2, 0, 0, 0, 0]);
    let diff = a.sub(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff, 1])));
}

#[test]
fn test_sbb1() {
    let a = BigUint::from_bytes(&[1, 0, 0, 0, 0]);
    let b = BigUint::from_bytes(&[2, 0, 0, 0, 0]);
    let (diff, borrow) = a.sbb(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff; NUM_BYTES])));
    assert(borrow >> (BITS_PER_BLOCK - 1) as u8 == 1); // 7 = number of bits
}

#[test]
fn test_mul1() {
    let a = BigUint::from_bytes(&[0xe]);
    let b = BigUint::from_bytes(&[8]);
    let res = a.mul(b);

    assert(res.eq(BigUint::from_bytes(&[0x70])));
}

// TODO: need to rework
/*
#[test]
fn test_mul2() {
    let mut bytes = [0xff as u8; NUM_BYTES];
    bytes[NUM_BYTES-1] = 15;

    let a = BigUint { bytes };
    let b = BigUint::from_bytes(&[16]);
    let res = a.mul(b);

    let mut expected_bytes = [0xff; NUM_BYTES];
    expected_bytes[0] = 240;
    assert(res.to_bytes() == expected_bytes);
}
*/

#[test]
fn test_extend_mul1() {
    let a = BigUint::from_bytes(&[2]);
    let b = BigUint::from_bytes(&[3]);
    let (lo, hi) = a.extend_mul(b);
    
    assert(lo.eq(BigUint::from_bytes(&[6])));
    assert(hi.eq(BigUint::zero()));
}

// TODO: Need to rework
/*
#[test]
fn test_extend_mul2() {
    let a = BigUint { bytes: [0xff; NUM_BYTES] };
    let b = a;
    let (lo, hi) = a.extend_mul(b);

    let mut hi_expect = [0xff; NUM_BYTES];
    hi_expect[0] = 0xfe;
    let hi_expect = BigUint { bytes: hi_expect };

    assert(lo.eq(BigUint::one()));
    assert(hi.eq(hi_expect));
}
*/

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

#[test]
fn test_sqrt1() {
    let a = BigUint::from_bytes(&[0, 0, 0, 0, 1]);
    let expected_sqrt = BigUint::from_bytes(&[0, 0, 1]);
    assert(a.sqrt().eq(expected_sqrt));
}

#[test]
fn test_sqrt2() {
    let num = BigUint::from_bytes_32(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 104, 203, 127, 80, 204, 48, 33, 247, 218, 52, 195, 241, 198]
    );
    let expected_sqrt = BigUint::from_bytes_32(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 136, 82, 99, 169, 29, 173, 225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    );
    assert(num.sqrt().eq(expected_sqrt));
    assert(expected_sqrt.mul(expected_sqrt).eq(num));
}

// TODO: Failed
#[test]
fn test_sqrt3() {
    // If not precise square
    let num = BigUint::from_bytes_32([
        84, 131, 32, 9, 152, 117, 67, 219,
        205, 41, 62, 115, 54, 121, 56, 101,
        148, 26, 32, 216, 170, 246, 39, 251,
        3, 35, 247, 218, 52, 195, 241, 198
    ]);

    let expected_sqrt = BigUint::from_bytes_32(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 136, 82, 99, 169, 29, 173, 225, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    );
    assert(num.sqrt().eq(expected_sqrt));
}

#[test]
fn test_sqrt4() {
    let a = BigUint::from_bytes(&[1, 0, 0, 0, 1]);
    let expected_sqrt = BigUint::from_bytes(&[0, 0, 1]);
    assert(a.sqrt().eq(expected_sqrt));
}

#[test]
fn test_negative1() {
    let a = BigUint::from_bytes(&[1]);
    let expected_neg = BigUint { blocks: [0xffffffff; NUM_BLOCKS ] };
    assert(a.negative().eq(expected_neg));
}

#[test]
fn test_negative2() {
    let a = BigUint::from_bytes(&[0xff, 0xff, 120, 230]);
    let mut expected = [0xff; NUM_BYTES];
    expected[0] = 1;
    expected[1] = 0;
    expected[2] = 135;
    expected[3] = 25;

    assert(a.negative().to_bytes() == expected);
}
