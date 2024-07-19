# secp256k1_XMD:SHA-256_SSWU_RO_ hash-to-curve in Noir

## Quick overview
Implementation of the hash-to-curve algorithm based on [this description](https://datatracker.ietf.org/doc/id/draft-irtf-cfrg-hash-to-curve-06.html).  
Checked with the test described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appendix-J.8.1).

## The algorithm
```
hash_to_curve(msg)

Input: msg, an arbitrary-length byte string.
Output: P, a point in the secp256k1 curve.

Steps:
1. u = hash_to_field(msg)
2. Q0 = map_to_curve(u[0])
3. Q1 = map_to_curve(u[1])
4. P = iso_map(Q0) + iso_map(Q1)
5. return P
```

### hash_to_field
Implemented in `src/hash_to_field.nr`.  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#hashtofield).

### map_to_curve
Implemented in `src/map_to_curve.nr`.  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#simple-swu).

### iso_map
Implemented in `src/iso_map.nr`.  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appx-iso-secp256k1).

### point_add
Implemented in `src/point_add.nr`.  
Follows the algorithm described [here](https://www.rareskills.io/post/elliptic-curve-addition).

### BigUint
Auxiliary library of large numbers implemented in `src/hash_to_field.nr`. Based on [this code](https://github.com/shuklaayush/noir-bigint/tree/main/crates/biguint).  

## Build and Run
1. Install Noir by following [these instructions](https://noir-lang.org/docs/getting_started/installation/).
2. Change [MSG_LEN](https://github.com/distributed-lab/noir-plume/blob/b75a6e06cbd85d1df400f0cce1e05d3c7c68be54/src/constants.nr#L1) constant to the length of the message you want to pass to the program.
3. Run `noir check` command.
4. Pass the bytes of your message to the Prover.toml file generated by the compiler.
5. Run `noir prove` command to get output to the console.

## Constraints
For msg of length 3:  
```
ACIR Opcodes: 1615724  
Backend Circuit Size: 3786276
```