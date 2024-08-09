# Tests

Plume, which is written in sage. Generates test values `r`, `sk` of 32 bytes and msg of arbitrary length, then runs `nargo check`, fills in the required values in `Prover.toml` and changes the files `main.nr` and `constants.nr`.

## Build and Run

1. Install SageMath by following [these instructions](https://doc.sagemath.org/html/en/installation/index.html).
2. To start, select the version of plume you want to run "v1" or "v2", then the number of bytes for msg (non-negative number). For example, `sage gen_data.sage v2 32`.

After that, you can run the program without interfering with the Noir code.
