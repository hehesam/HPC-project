# HPC Project: Matrix Multiplication Optimisation

A staged study of optimising the n x n matrix multiplication in [MatMul.c](MatMul.c). Each stage targets the bottleneck identified by the previous one: compiler flags, sequential blocking, multithreading (OpenMP), distributed memory (MPI), and GPU acceleration (CUDA).

The detailed CUDA report is at [Cuda/REPORT.md](Cuda/REPORT.md).

## Hardware

| Component | Detail |
|-----------|--------|
| CPU       | Intel i9-12900K, 12 cores / 24 threads, 3.20 GHz, Linux (workstation `wk005`) |
| GPU       | NVIDIA Tesla T4 (Turing, CC 7.5), 16 GB GDDR6 -- via Google Colab (CUDA experiments only) |
| Compilers | GCC, Intel ICC / ICX (oneAPI), `mpicc` / `mpiicc`, `nvcc` 13.0 |

Setup: `source /opt/intel/oneapi/setvars.sh` for the Intel toolchain; `advixe-gui` for Intel Advisor.

## Reference baselines (n = 10000, the headline numbers used for every speedup)

| Reference         | Time      | Definition                                                 |
|-------------------|-----------|------------------------------------------------------------|
| `T_seq_naive`     | 365.59 s  | Sequential `MatMul.c`, ICC `-O3`, no blocking (worst case) |
| **`T_seq_best`**  | **149.13 s** | Sequential `MatMulBlocking.c`, ICC `-O3`, **the BEST sequential -- used as the reference for every speedup below** |

All speedups in this README are `T_seq_best / T_variant`.

# Stage 1 -- Compiler optimisation

What changes: only the compiler flag, source code unchanged. Goal: see how much the compiler can do alone with auto-vectorisation and standard optimisations.

| Compiler | Flag    | n     | First-loop time | Speedup vs `T_seq_best` |
|----------|---------|-------|-----------------|--------------------------|
| gcc      | -O0     | 5000  | 211.0  s        |   --   (different n)     |
| gcc      | -O1     | 5000  |  67.4  s        |   --                     |
| gcc      | -O2     | 5000  |  54.4  s        |   --                     |
| gcc      | -O3     | 5000  |  37.5  s        |   --                     |
| icc      | -O3     | 5000  |  18.3  s        |   --                     |
| icc      | -O3     | 10000 | 365.59 s        | 0.41x  (= `T_seq_naive`) |
| icx      | -O3     | 10000 |  50.14 s (*)    |   --                     |

(*) `icx -O3` at n=10000 is not directly comparable to ICC because of run-time variance and the absence of the same blocking transformation; the meaningful sequential reference for the rest of the table is the ICC + blocking row of Stage 2.

Take-away: the compiler alone gives a **~10x speedup** going from `gcc -O0` to `icc -O3`, but the kernel is still memory-bound by the column-strided access of `B[k][j]` -- which Stage 2 fixes by blocking.

# Stage 2 -- Sequential blocking

What changes: `MatMul.c` -> [MatMulBlocking.c](MatMulBlocking.c) -- the inner loops are tiled into cache-sized blocks so each loaded element of B is reused before being evicted from L1/L2. Same compiler flags as Stage 1.

| Configuration          | n     | Time     | Speedup vs `T_seq_naive` (365.59 s) |
|------------------------|-------|----------|--------------------------------------|
| ICC -O3, no blocking   | 10000 | 365.59 s | 1.00x                                |
| **ICC -O3 + blocking** | **10000** | **149.13 s** | **2.45x  (= `T_seq_best`)**       |

This is the **BEST sequential** number; everything from now on is benchmarked against it.

# Stage 3 -- OpenMP (shared-memory parallelism)

Source: [MatMulOpenMP.c](MatMulOpenMP.c) and [MatMulOpenMP_Blocking.c](MatMulOpenMP_Blocking.c). The outer loop is annotated with `#pragma omp parallel for`. Compiled with `icc -xHost -qopenmp`.

| Configuration                       | Threads | Time    | Speedup |
|-------------------------------------|---------|---------|---------|
| OpenMP, no blocking                 | 24      | 43.57 s |  3.42x  |
| OpenMP + blocking                   |  8      | 23.19 s |  6.43x  |
| OpenMP + blocking                   | 12      | 21.45 s |  6.95x  |
| OpenMP + blocking                   | 16      | 17.91 s |  8.33x  |
| OpenMP + blocking                   | 32      | 15.62 s |  9.55x  |
| **OpenMP + blocking**               | **24**  | **14.36 s** | **10.39x** |
| OpenMP + blocking, schedule(dynamic)| 24      | 15.04 s | 9.92x   |
| OpenMP + blocking, schedule(guided) | 24      | 15.54 s | 9.60x   |
| OpenMP + blocking, schedule(static, 4) | 24   | 14.40 s | 10.36x  |

Best: **24 threads + blocking + default static schedule = 14.36 s, 10.39x speedup**. Adding more than 24 threads (= the i9's logical thread count) hurts because of contention.

# Stage 4 -- MPI (distributed-memory parallelism)

Source: [MatMulMPI.c](MatMulMPI.c) (basic), [MatMulMPI_manual.c](MatMulMPI_manual.c) (manual row distribution), [MatMulMPI_blocking.c](MatMulMPI_blocking.c) (with cache blocking). Compiled with `mpicc -O3 -march=native` or `mpiicc -O3`.

| Variant                              | Procs | Time     | Speedup |
|--------------------------------------|-------|----------|---------|
| MPI basic, mpicc -O0                 |  4    | 350.65 s | 0.43x   |
| MPI basic, mpicc -O3                 |  4    | 153.83 s | 0.97x   |
| MPI basic, mpicc -O3                 | 24    | 127.62 s | 1.17x   |
| MPI manual distribution, -O3         | 12    | 129.22 s | 1.15x   |
| MPI + blocking 32, -O3 -march=native | 24    |  42.88 s | 3.48x   |
| MPI + blocking 8                     | 24    |  16.52 s | 9.03x   |
| MPI + blocking 16                    |  4    |  17.20 s | 8.67x   |
| MPI + blocking 16                    | 12    |  15.95 s | 9.35x   |
| **MPI + blocking 16**                | **6** | **13.73 s** | **10.86x** |

Best: **6 procs + blocking 16 = 13.73 s, 10.86x speedup**. Block size 16 is the sweet spot; smaller (8) and larger (32) blocks are both slower because of L1 fit.

OpenMP and MPI peak at essentially the same wall-clock time on this CPU (14.4 s vs 13.7 s) -- the i9-12900K has run out of cores to throw at the problem. The next stage moves to a different machine entirely (a GPU) to break that ceiling.

# Stage 5 -- CUDA (GPU acceleration)

Five sub-experiments on a Tesla T4 via Google Colab, in both FP32 and FP64. Full details, including hotspot analysis, NCU metrics, and conceptual background on tiling and cuBLAS, are in **[Cuda/REPORT.md](Cuda/REPORT.md)**.

Source files: [Cuda/MatMulCuda.cu](Cuda/MatMulCuda.cu), [Cuda/MatMulCudaTiled.cu](Cuda/MatMulCudaTiled.cu), [Cuda/MatMulCublas.cu](Cuda/MatMulCublas.cu).

| Sub-experiment                       | Best config  | Precision | Total time | Speedup     | % of T4 peak  |
|--------------------------------------|--------------|-----------|------------|-------------|---------------|
| 1. Naive 2D-grid (one thread per `C[i][j]`) | -          | FP64      | 9.93 s     | 15.02x      |  85.6% FP64   |
| 2. Naive + block-size sweep          | BLOCK=32     | FP32      | 4.24 s     | 35.18x      |   6.5% FP32   |
| 3. Shared-memory tiled               | TILE=16      | FP32      | 3.05 s     | 48.93x      |   8.6% FP32   |
| 4. Tiled + tile-size sweep           | TILE=32 (*)  | FP32      | 2.65 s     | 56.17x      |  11.5% FP32   |
| 5. cuBLAS (Dgemm)                    | vendor       | FP64      | 8.90 s     | 16.77x      | 100.0% FP64 (ceiling) |
| **5. cuBLAS (Sgemm)**                | **vendor**   | **FP32**  | **0.93 s** | **159.66x** | **59.0% FP32** |

(*) The TILE=32 result is at n=9984 (the closest multiple of 32 to 10000); times scaled by `(10000/9984)^3 = 1.00481` to be comparable.

Cross-host caveat: CUDA times are on the T4 GPU, all reference times are on the i9-12900K CPU. We keep the same reference so all stages of this project sit on a single comparable axis.

# Final consolidated speedup chart (vs `T_seq_best = 149.13 s`)

```
Stage 0 reference (T_seq_naive)    *0.4x  *(slower than reference)
Stage 2 sequential blocking        #                                                                          1.0x   <-- T_seq_best
Stage 3 OpenMP best                ##########                                                                10.4x
Stage 4 MPI best                   ##########                                                                10.9x
Stage 5 CUDA naive  (FP64)         ###############                                                           15.0x
Stage 5 CUDA naive  (FP32)         ###################################                                       35.2x
Stage 5 CUDA tiled  (FP64)         ################                                                          15.6x
Stage 5 CUDA cuBLAS (FP64)         #################                                                         16.8x
Stage 5 CUDA tiled  (FP32)         #########################################################                 56.2x
Stage 5 CUDA cuBLAS (FP32)         ###########################################################################################################################################################  159.7x
                                   |----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|
                                   0    10   20   30   40   50   60   70   80   90   100  110  120  130  140  150  160
```

# Files in this repository

| File                                          | Stage | Purpose                                      |
|-----------------------------------------------|-------|----------------------------------------------|
| [MatMul.c](MatMul.c)                          | 1     | Original triple-loop matmul (`double`, n=5000 default) |
| [MatMulBlocking.c](MatMulBlocking.c)          | 2     | Sequential blocking version (`T_seq_best`)   |
| [MatMulOpenMP.c](MatMulOpenMP.c)              | 3     | OpenMP, no blocking                          |
| [MatMulOpenMP_Blocking.c](MatMulOpenMP_Blocking.c) | 3 | OpenMP + blocking                            |
| [MatMulMPI.c](MatMulMPI.c)                    | 4     | MPI, basic distribution                      |
| [MatMulMPI_manual.c](MatMulMPI_manual.c)      | 4     | MPI, manual row distribution                 |
| [MatMulMPI_blocking.c](MatMulMPI_blocking.c)  | 4     | MPI + cache blocking                         |
| [Cuda/MatMulCuda.cu](Cuda/MatMulCuda.cu)      | 5.1-5.2 | Naive CUDA kernel (one thread per `C[i][j]`) |
| [Cuda/MatMulCudaTiled.cu](Cuda/MatMulCudaTiled.cu) | 5.3-5.4 | Shared-memory tiled CUDA kernel        |
| [Cuda/MatMulCublas.cu](Cuda/MatMulCublas.cu)  | 5.5   | cuBLAS Sgemm / Dgemm reference               |
| [Cuda/REPORT.md](Cuda/REPORT.md)              | 5     | **Full CUDA report** (hardware, concepts, all sub-experiments) |
| [Cuda/HPC1.0.ipynb](Cuda/HPC1.0.ipynb)        | 5     | Colab notebook used to compile/run/profile the CUDA code |
| [SystemConfiguration.txt](SystemConfiguration.txt) | -- | Workstation hardware dump                  |
| `seq-o*.svg`, `n10k-*.svg`                    | 1-3   | Intel Advisor / vectorisation reports        |

# External resources

* Project Google Doc: https://docs.google.com/document/d/1qt4il0NrqpDt9coAq8w0jO6MP3vAU-j10cAJX2-bWlo/edit?usp=sharing
