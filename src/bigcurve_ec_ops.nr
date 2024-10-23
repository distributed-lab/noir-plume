use noir_bigcurve::curves::secp256k1::{Secp256k1, Secp256k1Scalar};
use noir_bigcurve::BigCurve;
use noir_bigcurve::scalar_field::ScalarField;

use bignum::BigNum;

pub fn test_point_mul() {
    let p: Secp256k1 = BigCurve::one();

    let scalar: Secp256k1Scalar = ScalarField::from(0x01FCE4E7F429983A9B2D414E5E365B8E4D09218BBE4E01A5412C2BDEABCD1234); 

    let actual = p.mul(scalar);

    let expected: Secp256k1 = BigCurve{
        x: BigNum::from_array([0xED1348DED1A946431F8E7CB2153010, 0xD855FF377B93C6F5E8A5D78DB8C1FC, 0x9B1E]),
        y: BigNum::from_array([0xAC9706B450D24A5C69784A41A015D6, 0xA17B8C61586702A28F714251F1F8DE, 0x0F4F]),
        is_infinity: false
    };  

    assert(actual == expected);
}
