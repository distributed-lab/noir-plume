# Benchmark

## Environment

### Machine

MacBook Pro M2 MAX 32 GB RAM 1 TB storage

### Nargo

```bash
nargo --version

nargo version = 0.35.0
noirc version = 0.35.0+51ae1b324cd73fdb4fe3695b5d483a44b4aff4a9
(git version hash: 51ae1b324cd73fdb4fe3695b5d483a44b4aff4a9, is dirty: false)
```

### Barrettenberg

```bash
bb --version

0.56.0
```

## Native Scalar Multiplication

ACIR opcodes: 255449

Brillig opcodes: 0

nargo check: 0.293 seconds

nargo execute --force: 5.729 seconds

bb prove: 41.769 seconds

bb write_vk: 36.720 seconds

bb verify: 0.053 seconds

bb prove_ultra_honk: 18.856 seconds

bb write_vk_ultra_honk: 14.975 seconds

bb verify_ultra_honk: 0.06 seconds

## BigNum Scalar Multiplication

ACIR opcodes: 35646

Brillig opcodes: 13504

nargo check: 0.217 seconds

nargo execute --force: 2 minutes 1.06 seconds

bb prove: 1.666 seconds

bb write_vk: 1.478 seconds

bb verify: 0.053 seconds

bb prove_ultra_honk: 0.910 seconds

bb write_vk_ultra_honk: 0.716 seconds

bb verify_ultra_honk: 0.062 seconds

## BigCurve Scalar Multiplication

ACIR opcodes: 22203

Brillig opcodes: 270071

nargo check: 0.993 seconds

nargo execute --force: 13.312 seconds

bb prove: 1.1 seconds

bb write_vk: 1.129 seconds

bb verify: 0.052 seconds

bb prove_ultra_honk: 0.747 seconds

bb write_vk_ultra_honk: 0.659 seconds

bb verify_ultra_honk: 0.058 seconds
