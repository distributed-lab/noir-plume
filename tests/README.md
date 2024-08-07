# Tests

Plume, which is written in sage. Generates test values `r`, `sk` and `msg` 32 bytes long, then runs `nargo check`, fills in the required values in `Prover.toml`, and finally runs the commands `nargo prove` and `nargo verify`.

## Build and Run

1. Install SageMath by following [these instructions](https://doc.sagemath.org/html/en/installation/index.html).
2. To start, select the version of plume you want to test and uncomment the corresponding line in [main.nr](../crates/use/src/main.nr), and comment out the other.
3. Change the MSG_LEN value in the [constants](../crates/plume/src/constants.nr) file to 32.
4. Run test.sage script of the appropriate version using the command `sage test.sage v1` or `sage test.sage v2`.
