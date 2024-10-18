# Plume in Noir

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Noir CI 🌌](https://github.com/distributed-lab/noir-plume/actions/workflows/noir.yml/badge.svg)](https://github.com/distributed-lab/noir-plume/actions/workflows/noir.yml)

Plume is needed to confirm your identity without disclosing your private data, i.e. [zero-knowledge proof](https://en.wikipedia.org/wiki/Zero-knowledge_proof). Plume has another feature: you can send a message from a private group using special group message. For more details visit <https://blog.aayushg.com/nullifier/>.

## How to use?

### Add dependency to your project's `Nargo.toml`

```toml
[dependencies]
plume = { git = "https://github.com/distributed-lab/noir-plume", tag = "v0.1.2", directory = "crates/plume"}
```

### Use in your `Noir` code as following

```rust
use plume::plume_v1;

...

plume_v1(msg, c, s, pk, nullifier);
```

Or in case you prefer 2 version:

```rust
use plume::plume_v2;

...

plume_v2(msg, c, s, pk, nullifier);
```

### Example

See the example in `crates/use`. For proving data generation, check out our `SageMath` [implementation](./etc).

## Benchmark

We have provided information regarding different computational statistics such as constraints amount and time for various activities, see [Benchmark.md](./BENCHMARK.md)

## Miscellaneous

### Message Lenght Restriction

Due to `Noir` specifics and generics limitations, message length is hardcoded to be constant value `32`.
In case you need to change it, see [constants.nr](./crates/plume/src/constants.nr).

### Cryptography

In order to bring in `PLUME` to `Noir`, we needed to implement `secp256k1_XMD:SHA-256_SSWU_RO_` hash-to-curve algorithm.

Based on [this description](https://datatracker.ietf.org/doc/id/draft-irtf-cfrg-hash-to-curve-06.html).  
Testes using [this data](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appendix-J.8.1).

#### The algorithm

```bash
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

##### hash_to_field

Implemented in [hash_to_field.nr](crates/plume/src/hash_to_field.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#hashtofield).

##### map_to_curve

Implemented in [map_to_curve.nr](crates/plume/src/map_to_curve.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#simple-swu).

##### iso_map

Implemented in [iso_map.nr](crates/plume/src/iso_map.nr).  
Follows the algorithm described [here](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appx-iso-secp256k1).

##### Elliptic Curve operations

Implemented in [ec_ops.nr](crates/plume/src/ec_ops.nr).  
Follows the algorithm described [here](https://www.rareskills.io/post/elliptic-curve-addition).
