# Plume
Plume is needed to confirm your identity without disclosing your private data, i.e. [zero-knowledge proof](https://en.wikipedia.org/wiki/Zero-knowledge_proof). Plume has another feature: you can send a message from a private group using special group message. For more details visit https://blog.aayushg.com/nullifier/

## How to use?
To use plume, you need 2 32-byte values for r and sk (secret key), and a message of arbitrary length (these values can be randomly generated). You can use the formulas described in the [plume document](https://aayushg.com/thesis.pdf) or [test.sage](tests/test.sage) to calculate the corresponding `msg`, `c`, `s`, `pk`, and `nullifier` values. After that, follow the `Build and Run` instructions to verify that the data is correct.


### Build and Run
1. Install Noir by following [these instructions](https://noir-lang.org/docs/getting_started/installation/).
2. Install Barretenberg by following [these instructions](https://noir-lang.org/docs/getting_started/backend/).
3. Change [MSG_LEN](src/constants.nr) constant to the length of the message you want to pass to the program.
4. Run `noir check` command.
5. Pass the bytes of your message, `c` and `s` constants, `nullifier` and `pk` (public key) points in format `[[x_bytes], [y_bytes]]` to the `Prover.toml` file generated by the compiler.
6. Run `noir execute plume` command to generate target directory
7. Run `bb prove -b ./target/use.json -w ./target/plume.gz -o ./target/proof` to generate proof for program.
8. Compute verification key with command: `bb write_vk -b ./target/use.json -o ./target/vk`.
9. Verify proof with command: `bb verify -k ./target/vk -o ./target/proof`


### Constraints
For plume_v1 and msg of length 29:  
```
ACIR Opcodes: 4556085
Backend Circuit Size: 17125141
```

For plume_v2 and msg of length 29:
```
ACIR Opcodes: 4555884
Backend Circuit Size: 17117111
```

## secp256k1_XMD:SHA-256_SSWU_RO_ hash-to-curve in Noir

### Quick overview
Implementation of the hash-to-curve algorithm based on [this description](https://datatracker.ietf.org/doc/id/draft-irtf-cfrg-hash-to-curve-06.html).  
Checked with the test described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appendix-J.8.1).

### The algorithm
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

#### hash_to_field
Implemented in [hash_to_field.nr](crates/plume/src/hash_to_field.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#hashtofield).

#### map_to_curve
Implemented in [map_to_curve.nr](crates/plume/src/map_to_curve.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#simple-swu).

#### iso_map
Implemented in [iso_map.nr](crates/plume/src/iso_map.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appx-iso-secp256k1).

#### Elliptic Curve operations
Implemented in [ec_ops.nr](crates/plume/src/ec_ops.nr).  
Follows the algorithm described [here](https://www.rareskills.io/post/elliptic-curve-addition).

#### BigUint
Auxiliary library of large numbers implemented in [biguint.nr](crates/plume/src/biguint.nr). Based on [this code](https://github.com/shuklaayush/noir-bigint/tree/main/crates/biguint).  

### Constraints
For msg of length 3:  
```
ACIR Opcodes: 1615724  
Backend Circuit Size: 3786276
```
