// Based on the code https://github.com/shuklaayush/noir-bigint
use dep::std::wrapping_sub;
use dep::std::bigint::Secpk1Fq;

// Note: If you need a different number of bytes, change only this variable
global NUM_BLOCKS: u64 = 12;

// Fixed value for u32 blocks arrary,
// Can optimize to 255/8 = 15 bytes, otherwise u8 bit shift doesn't work properly
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

// All conversion operations with bytes and bits are performed in little endian format
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

    pub fn from_Secpk1Fq(num: Secpk1Fq) -> Self {
        BigUint::from_bytes_32(BigUint::to_u8_32(num.to_le_bytes()))
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

    // Private, helper method
    fn to_u8_arr(arr: [u8; 32]) -> [u8] {
        arr
    }
    fn to_u8_32(arr: [u8]) -> [u8; 32] {
        let mut res = [0 as u8; 32];
        for i in 0..arr.len() {
            res[i] = arr[i];
        }
        res
    }

    pub fn to_Secpk1Fq(self: Self) -> Secpk1Fq {
        Secpk1Fq::from_le_bytes(BigUint::to_u8_arr(self.to_bytes_32()))
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

    // low, high results
    pub fn mul(self: Self, other: Self) -> (Self, Self) {
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

    // most significant bit
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

            for i in 0..NUM_BYTES*8+1 {
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

    // Use simple binary search algorithm
    // https://programmercave.com/blog/2023/03/03/Efficiently-Finding-the-Square-Root-of-a-Number-Linear-Search-vs-Binary-Search
    pub fn sqrt(self: Self) -> Self {
        let mut mid = self;
        let zero = BigUint::zero();
        let one  = BigUint::one();

        if self.eq(zero) {
            mid
        } else {
            let mut beg = zero;
            let mut end = mid;
            let mut done = false;
            
            // Max number of bits
            for _ in 0..NUM_BYTES*8 {
                if !done {
                    // shr1 replace .div(2) operation
                    mid = beg.add(end).shr1();
                    let (low, high) = mid.mul(mid);

                    if (!high.eq(zero) | low.gt(self)) {
                        end = mid.sub(one);
                    } else {
                        if (low.lt(self)) {
                            beg = mid.add(one);
                        } else {
                            done = true;
                            beg = mid;
                        }
                    }
                }
            }
            if end.gt(beg) { beg } else { end }
        }
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


// Failed if NUM_BLOCKS is not equal to 12
/*
#[test]
fn test_from_bytes1() {
    let a = BigUint::from_bytes(&[2]);

    assert(
        a.eq(
            BigUint {
        blocks: [
            2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
            0xffffffff, 0xffffff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
            0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
            0xffffffff, 0xffffffff, 0xffffffff, 0, 0, 0, 0,
        ]
    }
        )
    );
}
*/

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
    let a = BigUint::from_bytes(&[0xff, 0xff, 0xff, 0xff]);
    let b = BigUint::from_bytes(&[1]);
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
    let a = BigUint::from_bytes(&[1, 2]);
    let b = BigUint::from_bytes(&[2]);
    let diff = a.sub(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff, 1])));
}

#[test]
fn test_sbb1() {
    let a = BigUint::from_bytes(&[1]);
    let b = BigUint::from_bytes(&[2]);
    let (diff, borrow) = a.sbb(b);

    assert(diff.eq(BigUint::from_bytes(&[0xff; NUM_BYTES])));
    assert(borrow >> (BITS_PER_BLOCK - 1) as u8 == 1);
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
    let a = BigUint { blocks: [0xffffffff; NUM_BLOCKS] };
    let b = BigUint { blocks: [0xffffffff; NUM_BLOCKS] };
    let (lo, hi) = a.mul(b);

    let mut expected_hi = [0xff; NUM_BYTES];
    expected_hi[0] = 0xfe;

    assert(lo.eq(BigUint::one()));
    assert(hi.to_bytes() == expected_hi);
}

#[test]
fn test_cmp1() {
    let a = BigUint::from_bytes(&[2, 0]);
    let b = BigUint::from_bytes(&[0, 2]);

    assert(!a.eq(b));
    assert(!a.gte(b));

    assert(a.lt(b));
    assert(!a.gt(b));
}

#[test]
fn test_cmp2() {
    let a = BigUint::from_bytes(&[0, 2]);
    let b = BigUint::from_bytes(&[0, 2]);

    assert(a.eq(b));
    assert(a.gte(b));

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
    assert(r.eq(BigUint::zero()));
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
    let expected_sqrt = BigUint::from_bytes(&
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 136, 82, 99, 169, 29, 173, 225]
    );
    assert(num.sqrt().eq(expected_sqrt));
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

    let expected_sqrt = BigUint::from_bytes(&[
        231, 95, 119, 147, 127, 144, 147, 250,
        8, 137, 82, 99, 169, 29, 173, 225
    ]);
    assert(num.sqrt().eq(expected_sqrt));
}

#[test]
fn test_sqrt4() {
    let a = BigUint::from_bytes(&[1, 0, 0, 0, 1]);
    let expected_sqrt = BigUint::from_bytes(&[0, 0, 1]);
    assert(a.sqrt().eq(expected_sqrt));
}

#[test]
fn test_sqrt5() {
    let num = BigUint::from_bytes(&[
        54, 92, 89, 51, 110, 45, 220, 37, 12, 215, 31, 53,
        226, 99, 42, 136, 174, 218, 72, 5, 219, 84, 88, 79,
        47, 203, 166, 177, 29, 248, 176, 118, 211, 178, 213, 113,
        215, 200, 225, 141, 222, 206, 141, 245, 189, 52, 228, 67
    ]);

    let expected_sqrt = BigUint::from_bytes(&[
        234, 147, 133, 52, 134, 34, 197, 229, 40, 24, 71, 1,
        103, 112, 238, 171, 127, 97, 123, 39, 163, 129, 213, 131
    ]);
    assert(num.sqrt().eq(expected_sqrt));
}

#[test]
fn test_sqrt6() {
    let num = BigUint::from_bytes(&[
        3, 114, 131, 27, 209, 209, 237, 216, 83, 208, 252, 34,
        139, 5, 35, 68, 33, 235, 97, 130, 162, 58, 84, 139,
        106, 241, 132, 3, 70, 86, 197, 169, 14, 78, 28, 47,
        135, 171, 48, 79, 117, 22, 71, 195, 179, 156, 149, 243
    ]);

    let expected_sqrt = BigUint::from_bytes(&[
        160, 93, 80, 149, 247, 156, 64, 180, 2, 132, 112, 226,
        74, 207, 234, 203, 104, 93, 0, 56, 75, 14, 183, 249
    ]);
    assert(num.sqrt().eq(expected_sqrt));
}
