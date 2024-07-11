use crate::hash_to_field::hash_to_field;
use crate::map_to_curve::MapToCurve;
type Point = (Field, Field);

pub fn hash_to_curve<N>(msg: [u8; N]) -> Point {
    // here input some unknown number arrays

    // Step 1: u = hash_to_field(msg)
    // Unfortunately need to much computations (more than 2 minutes of compilation)
    // let h2f = hash_to_field(msg);

    let h2f: [[u8; 32]; 2] = [
        [
            97, 43, 138, 176, 151, 243, 115, 72,
            138, 225, 103, 71, 84, 31, 73, 62,
            244, 209, 206, 148, 223, 59, 30, 96,
            247, 161, 121, 54, 93, 171, 138, 18
        ],
        [
            0, 158, 104, 228, 242, 160, 170, 77,
            4, 139, 81, 3, 106, 231, 27, 83,
            220, 149, 200, 117, 204, 253, 208, 19,
            168, 149, 181, 163, 93, 182, 151, 88
        ]
    ];

    println(h2f);

    // Step2: Q0 = map_to_curve(u[0])
    let mut m2c_q0 = MapToCurve(h2f[0]);

    (0, 0)
}

/*
msg     = abc
P.x     = 3377e01eab42db296b512293120c6cee72b6ecf9f9205760bd9ff1
          1fb3cb2c4b
P.y     = 7f95890f33efebd1044d382a01b1bee0900fb6116f94688d487c6c
          7b9c8371f6
u[0]    = 128aab5d3679a1f7601e3bdf94ced1f43e491f544767e18a4873f3
          97b08a2b61
u[1]    = 5897b65da3b595a813d0fdcc75c895dc531be76a03518b044daaa0
          f2e4689e00
Q0.x    = 07dd9432d426845fb19857d1b3a91722436604ccbbbadad8523b8f
          c38a5322d7
Q0.y    = 604588ef5138cffe3277bbd590b8550bcbe0e523bbaf1bed4014a4
          67122eb33f
Q1.x    = e9ef9794d15d4e77dde751e06c182782046b8dac05f8491eb88764
          fc65321f78
Q1.y    = cb07ce53670d5314bf236ee2c871455c562dd76314aa41f012919f
          e8e7f717b3
*/
