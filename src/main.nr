pub mod native_ec_ops;
pub mod bignum_ec_ops;
pub mod bigcurve_ec_ops;

// use crate::native_ec_ops::test_point_mul;
use crate::bignum_ec_ops::test_point_mul;
//use crate::bigcurve_ec_ops::test_point_mul;

pub fn main() {
    test_point_mul();
}
