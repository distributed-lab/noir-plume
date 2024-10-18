# PLUME in Sage

This directory contains [sage](https://www.sagemath.org/) implementation of PLUME.

## Scripts

To streamline demonstration of `PLUME` usage in `Noir`, we attach the below scripts.

### Generation of the `Prover.toml` data

Generates random 32-byte values of `r` and `sk`, random message-length dependent `msg` and computes other necessary information
for ZKP issuing.

### Managing `PLUME` version

Comments out the code in `/crates/use/src/main.nr` enabling either `v1` or `v2` version.

### Managing message length

Changes `MSG_LEN` constant in `crates/plume/src/constants.nr`.

## How to use?

### Prerequisites

Install SageMath by following [these instructions](https://doc.sagemath.org/html/en/installation/index.html).

### Launch Sage

Select the version of plume you want to run: either "v1" or "v2", then the number of bytes for msg (non-negative number) and run `main.sage` supplying these as CLI arguments, for example:

```bash
sage main.sage v2 32
```
