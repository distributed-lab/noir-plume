use dep::std::wrapping_sub;

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
    
    pub fn to_bytes(self: Self) -> [u8; NUM_BYTES] {
        self.bytes
    }

    // -1 - left bigger; 0 - equal; 1 - right bigger
    pub fn cmp(self: Self, other: Self) -> i8 {
        for i in 0..NUM_BYTES {
            if self.bytes[i] < other.bytes[i] {
                1
            }
            if self.bytes[i] > other.bytes[i] {
                -1
            }
        }
        0
    }

    fn utils_adc(a: u8, b: u8, carry: u8) -> (u8, u8) {
        let ret = a as Field + b as Field + carry as Field;
        (ret as u8, (ret as u16 >> 8) as u8)
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

    
    fn utils_sbb(a: u8, b: u8, borrow: u8) -> (u8, u8) {
        // 7 = number of bits -1
        let ret = wrapping_sub(a as u16, b as u16 + (borrow as u16 >> 7));
        (ret as u8, (ret >> 8) as u8)
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


    pub fn nbits(self: Self) -> u64 {
        let mut res = 0 as u64;
        
        for i in 0..NUM_BYTES {
            let bits = (self.bytes[i] as Field).to_le_bits(8);

            for j in 0..8 {
                res += bits[j] as u64;
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
        assert(BigUint::zero().cmp(other) == 0);

        if self.cmp(other) == 1 {
            (BigUint::zero(), self)
        } else {
            let mut rem = self;
            let mut quo = BigUint::zero();

            let bit_diff = self.nbits() - other.nbits();
            let mut c = other.shl(bit_diff);

            for i in 0..NUM_BYTES*8 + 1 {
                if i <= bit_diff {
                    if rem.cmp(c) == -1 {
                        rem = rem.sub(c);
                        quo = quo.shl(1).add(BigUint::one());
                    } else {
                        quo = quo.shl(1);
                    }
                    c = c.shr1();
                }
            }
            (quo, rem)
        }
    }
}
