# PLUME in Noir

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Noir CI 🌌](https://github.com/distributed-lab/noir-plume/actions/workflows/noir.yml/badge.svg)](https://github.com/distributed-lab/noir-plume/actions/workflows/noir.yml)

Plume is needed to confirm your identity without disclosing your private data, i.e. [zero-knowledge proof](https://en.wikipedia.org/wiki/Zero-knowledge_proof). Plume has another feature: you can send a message from a private group using special group message. For more details visit <https://blog.aayushg.com/nullifier/>.

## Eager to try? 😎

### Add dependency to your project's `Nargo.toml`

```toml
[dependencies]
plume = { git = "https://github.com/distributed-lab/noir-plume", tag = "v1.0.0", directory = "crates/plume"}
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

### Examples

Check out how to generate proofs with PLUME in either `crates/use_v1` or `crates/use_v2`.
For proving data generation, see our `SageMath` [implementation](./etc).

## Benchmark 📊

We have provided information regarding different computational statistics such as constraints amount and time for various activities, see [Benchmark.md](./BENCHMARK.md)

## There is more? 🤯

In order to bring in `PLUME` to `Noir`, we needed to implement `secp256k1_XMD:SHA-256_SSWU_RO_` hash-to-curve algorithm, ergo now it is available in `Noir` ecosystem!

Based on [this description](https://datatracker.ietf.org/doc/id/draft-irtf-cfrg-hash-to-curve-06.html).  
Tested using [this data](https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-13.html#appendix-J.8.1).
