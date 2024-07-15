use crate::hash_to_field::hash_to_field;
use crate::map_to_curve::MapToCurve;
type Point = (Field, Field);

pub fn hash_to_curve<N>(msg: [u8; N]) -> Point {
    // here input some unknown number arrays

    // Step 1. u = hash_to_field(msg)
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

    // Step 2. Q0 = map_to_curve(u[0])
    // let mut (q0_x, q0_y) = MapToCurve(h2f[0]);

    let q0_x = [
        215, 34, 83, 138, 195, 143, 59, 82,
        216, 218, 186, 187, 204, 4, 102, 67,
        34, 23, 169, 179, 209, 87, 152, 177,
        95, 132, 38, 212, 50, 148, 221, 7
    ];
    let q0_y = [
        63, 179, 46, 18, 103, 164, 20, 64,
        237, 27, 175, 187, 35, 229, 224, 203,
        11, 85, 184, 144, 213, 187, 119, 50,
        254, 207, 56, 81, 239, 136, 69, 96
    ];

    // Step 3. Q0 = map_to_curve(u[1])
    // let mut (q1_x, q1_y) = MapToCurve(h2f[1]);

    let q1_x = [
        120, 31, 50, 101, 252, 100, 135, 184,
        30, 73, 248, 5, 172, 141, 107, 4,
        130, 39, 24, 108, 224, 81, 231, 221,
        119, 78, 93, 209, 148, 151, 239, 233
    ];
    let q1_y = [
        179, 23, 247, 231, 232, 159, 145, 18,
        240, 65, 170, 20, 99, 215, 45, 86,
        92, 69, 113, 200, 226, 110, 35, 191,
        20, 83, 13, 103, 83, 206, 7, 203
    ];

    // Step 4. Result = IsoMap(Q0) + IsoMap(Q1)
    // + here - PointAdd on EC
    // let mut 

    (0, 0)
}

/*
msg     = abc
P.x     = 3377e01eab42db296b512293120c6cee72b6ecf9f9205760bd9ff11fb3cb2c4b
P.y     = 7f95890f33efebd1044d382a01b1bee0900fb6116f94688d487c6c7b9c8371f6

u[0]    = 128aab5d3679a1f7601e3bdf94ced1f43e491f544767e18a4873f397b08a2b61
u[1]    = 5897b65da3b595a813d0fdcc75c895dc531be76a03518b044daaa0f2e4689e00

Q0.x    = 07dd9432d426845fb19857d1b3a91722436604ccbbbadad8523b8fc38a5322d7
Q0.y    = 604588ef5138cffe3277bbd590b8550bcbe0e523bbaf1bed4014a467122eb33f
Q1.x    = e9ef9794d15d4e77dde751e06c182782046b8dac05f8491eb88764fc65321f78
Q1.y    = cb07ce53670d5314bf236ee2c871455c562dd76314aa41f012919fe8e7f717b3
*/
