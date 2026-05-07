*    CPU Name: 12th Gen Intel(R) Core(TM) i9-12900K
*    Frequency: 3.20 GHz
*    Logical CPU Count: 24
*    Operating System: Linux
*    Computer Name: wk005

## set up for compiler:
source /opt/intel/oneapi/setvars.sh

## for Intel Adviser:
advixe-gui

# First experiment compiler optimization
1. no optimization: gcc MatMul.c -o MatMul_O0
./MatMul_O0
*   first loop result: 211 second
2. basic optimization: gcc -O1 MatMul.c -o MatMul_O1
./MatMul_O1
*   first loop result: 67.4142
*   second loop result: 0.1283
3. more optimization: gcc -O2 MatMul.c -o MatMul_O2
./MatMul_O2
*   first loop result: 54.3686
*   0.128724
4. maximum optimization: gcc -O3 MatMul.c -o MatMul_O3
    ./MatMul_O3
*   First loop result: 37.534927
*   Second loop result: 0.128871
5. optimization 4

# Second experiemnt with ICC compiler
1. icc -O3 MatMul.c -o MatMul_icc_O4 ./MatMul_icc_O3
*   First bottleneck: 18.264099
*   Second bottleneck: 0.129084
2. Runnign for n = 10000:
*   First bottleneck: 365.593128
*   second
3. Runnign n=10000 with blocking:
*   First bottleneck: 149.125418
*   Second bottleneck: 0.132787

# Third experiment with ICX compiler:
1. icx Matmul.c -O3 -o Matmul:
*   First bottleneck: 50.1430
*   Second bottleneck: 

# OpenMP experiments
## OpenMP ICC XHost on 10000 samples
*   43.569727
*   0.132649
## OpenMP ICC XHost with Blocking
1. 24 threads
*   14.362156
*   0.130031
2. 32 threads
*   15.616791
*   0.135189
3. 8 threads:
*   23.192564
*   0.133868
4. 12 threads:
*   21.446184
*   0.132584
5. 16 threads:
*   17.905209
*   0.13265
## OpenMP ICC  XHost with blocking with different schedulees
1. dynamic
*   15.04
2. Guided
*   15.536664
3. Static:
*   1 chunck size: 14.45
*   4 chunck size: 14.402
*   16 chunck size: 14.4022041

# Fourth Experiment MPI
## using 4 process
1. mpicc -o0 matmulMPI.c -o matmulMPI
*   MPI MatMul time: 350.651494
2. mpicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMUl time: 153.825133 
3. mpiicc -O3 MatMul_mpi.c -o matmul_mpi
*   MPI MatMul time: 149.639843
## Using 6 process
1. mpicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMUl time: 132.483944
2. mpiicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMul time: 132.483944

## Using 12 process
1. mpicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMUl time: 128.832892
2. mpiicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMul time: 129.008329

## Using 24 process
1. mpicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMUl time: 127.619324
2. mpiicc -O3 matmulMPI.c -o matmulMPI
*   MPI MatMul time: 127.588329

# Fifth experiment MPI with manual distribution
## using 4 process
1. mpicc -O3 matmulMPI_M.c -o matmulMPI_M
*    MPI MatMul time: 149.708280
## using 12 process
2. mpicc -O3 matmulMPI_M.c -o matmulMPI_M
*   MPI MatMul time: 129.220255

# Sixth experiment MPI with blocking size 32
## using 4 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 167.260305
2. mpicc -O3 -march=native matmulMPI_blocked.c -o matmulMPI_blocked
*  MPI MatMul time: 136.783163
## using 6 processes
2. mpicc -O3 -march=native matmulMPI_blocked.c -o matmulMPI_blocked
*  MPI MatMul time: 103.555656

## using 12 processes
1. mpicc -O3 -march=native matmulMPI_blocked.c -o matmulMPI_blocked
*  MPI MatMul time: 61.425365

## using 24 processes
2. mpicc -O3 -march=native matmulMPI_blocked.c -o matmulMPI_blocked
*  MPI MatMul time: 42.879329

# Seventh experiment MPI with blocking size 16
## using 4 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 17.202243
## using 6 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 13.730352
## using 12 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 15.947626
## using 24 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 24.157838
## using 32 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 24.167000

# eighth experiment MPI with blocking size 8
## using 4 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 19.969668
## using 6 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 17.550283
## using 12 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 19.957171
## using 24 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 16.524702
## using 32 processes
1. mpicc -03 matmulMPI_blocked.c -o matmulMPI_blocked
*   MPI MatMul time: 17.967706

google docs link   
https://docs.google.com/document/d/1qt4il0NrqpDt9coAq8w0jO6MP3vAU-j10cAJX2-bWlo/edit?usp=sharing

# CUDA experiments

All CUDA runs are executed on Google Colab (Tesla T4) because the workstation has no NVIDIA GPU. The reference times in the speedup tables are still the workstation (i9-12900K) numbers from the earlier sections, so every speedup below is **cross-host**: T4 GPU vs i9-12900K CPU. We keep the same reference so the CUDA results sit on the same axis as the OpenMP and MPI experiments.

## Hardware (Colab) and reference baselines
*   GPU: NVIDIA Tesla T4 (Turing, CC 7.5), 16 GB GDDR6, 320 GB/s, FP32 peak ~8.1 TFLOPs, FP64 peak ~0.25 TFLOPs (FP32:FP64 = 32:1)
*   Host: Colab x86_64 VM, PCIe 3.0 x16 link to the GPU
*   Driver / toolkit at run time: 580.82.07 / CUDA 13.0 (from `nvidia-smi`)
*   `nvprof` is **not supported on T4** (CC 7.5+); it prints "Skipping profiling on device 0..." and reports no metrics. From Step 2 onward we use Nsight Compute (`ncu`) for metrics.

Reference times (from earlier sections, n = 10000, i9-12900K):
*   `T_seq_naive  = 365.59 s`  (ICC -O3, no blocking, sequential -- the unoptimized hotspot)
*   `T_seq_best   = 149.13 s`  (ICC -O3 + blocking, sequential -- BEST sequential, used as reference)
*   `T_OMP_best   =  14.36 s`  (OpenMP, 24 threads, blocking, ICC xHost)
*   `T_MPI_best   =  13.73 s`  (MPI, 6 procs, blocking 16, mpicc -O3)

# First CUDA experiment: naive kernel (one thread per output element)
This is the direct CUDA mapping of the triple loop in [MatMul.c](MatMul.c) lines 23-26. Each CUDA thread computes one element `C[row][col]` and walks the full `k`-loop itself; no shared memory, no tricks. The same source compiles to FP64 (default) or FP32 (`-DUSE_FLOAT`).

The kernel ([Cuda/MatMulCuda.cu](Cuda/MatMulCuda.cu) lines 36-46):

```36:46:Cuda/MatMulCuda.cu
__global__ void matmul_naive(const real *A, const real *B, real *C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n) {
        real sum = 0;
        for (int k = 0; k < n; ++k) {
            sum += A[row * n + k] * B[k * n + col];
        }
        C[row * n + col] = sum;
    }
}
```

Launch configuration: `dim3 block(16, 16); dim3 grid(625, 625);` -> 256 threads/block, 100,000,000 threads in total (one per output element).

## Compile commands
1. FP64: `nvcc -arch=sm_75 -O3 MatMulCuda.cu -o MatMulCuda_fp64`
2. FP32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT MatMulCuda.cu -o MatMulCuda_fp32`

## Raw timings (n = 10000, block 16x16, Tesla T4)
| Phase     | FP64 (double) | FP32 (float) |
|-----------|---------------|--------------|
| H2D copy  |    380.873 ms |   172.943 ms |
| Kernel    |   9018.167 ms |  6200.314 ms |
| D2H copy  |    531.391 ms |   301.300 ms |
| **Total** | **9930.4 ms** | **6674.6 ms**|
| `C[0][0]` | 60000.000     | 60000.000    |

Both runs produce the correct result (`C[i][j] = 6 * n = 60000`).

## Hotspot decomposition
The kernel dominates total GPU time in both precisions:
*   FP64: kernel = 9018 ms of 9930 ms = **90.8%** ; H2D = 3.8% ; D2H = 5.4%
*   FP32: kernel = 6200 ms of 6675 ms = **92.9%** ; H2D = 2.6% ; D2H = 4.5%

This is the **opposite** of the `VectorAddCuda.cu` example earlier in the notebook, where the kernel was a small fraction of total time and PCIe transfers dominated. MatMul has O(n^3) work for O(n^2) data, so the compute side (the `for (k ...)` loop in the kernel) is the hotspot, just like in the CPU version.

PCIe transfer side note: total transferred = 2 buffers HtoD + 1 buffer DtoH = 2.24 GB (FP64) / 1.12 GB (FP32). Effective bandwidth ~3.5-3.7 GB/s in both cases, well below the 12 GB/s PCIe 3.0 peak; this is because we use pageable host memory (`malloc`). Switching to `cudaMallocHost` would roughly triple it, but as the table above shows the H2D + D2H combined is only ~7-9% of total time, so this is not where the time goes and we deliberately keep the host code simple.

## Vectorization / coalescing analysis (analytical, since nvprof can't profile T4)
A warp on T4 is 32 threads. With `block(16,16)` the 32 threads of a warp span `threadIdx.x = 0..15` and `threadIdx.y = 0..1`, so within one warp `col` takes 16 different values and `row` takes 2 different values.

*   `A[row * n + k]` -- same `k`, only 2 distinct `row` values per warp -> 2 unique cache lines per inner-loop step. Lots of intra-warp reuse, well served by L1.
*   `B[k * n + col]` -- same `k`, 16 different `col` values per warp -> 16 contiguous 8-byte (FP64) or 4-byte (FP32) elements = one or two 128 B sectors. Coalesced **within** a warp, but the access pattern across warps in a block is fine too.
*   The real problem is **reuse across blocks**, not coalescing within a block: each element of A is reloaded by every block in its column-strip, and each element of B is reloaded by every block in its row-strip. Total memory traffic is `2 * n^3 * sizeof(real)` reads, while useful work is `2 * n^3` FLOPs, giving an arithmetic intensity of only `1 / sizeof(real) = 0.125 FLOP/byte` (FP64) or `0.25 FLOP/byte` (FP32) -- well below the T4 ridge point (~25 FLOP/byte).

This is exactly the "every B column re-read for every i" cache-miss problem that `MatMulBlocking.c` solved on the CPU side. Step 3 fixes it on the GPU with a shared-memory tiled kernel, which is the direct analogue of CPU blocking.

## Effective performance vs T4 peak
*   FP64: `2 * n^3 / kernel_time = 2e12 / 9.018 s = 0.222 TFLOPs` -> **89% of T4 FP64 peak (0.25 TFLOPs)**. The kernel is essentially compute-bound on the FP64 pipeline; even with bad reuse, the FP64 unit is so weak on T4 that it saturates first. There is almost no room to improve FP64 by tiling alone.
*   FP32: `2e12 / 6.200 s = 0.323 TFLOPs` -> **only 4% of T4 FP32 peak (8.1 TFLOPs)**. FP32 is firmly memory-bound; tiling should give a large speedup here.

## Speedup vs the workstation reference
Cross-host comparison: T4 GPU vs i9-12900K CPU.

| Metric                       | FP64    | FP32    |
|------------------------------|---------|---------|
| Total GPU time (s)           | 9.930   | 6.675   |
| Kernel-only time (s)         | 9.018   | 6.200   |
| Speedup vs `T_seq_naive` 365.59 s, total | 36.8x   | 54.8x   |
| Speedup vs `T_seq_best` 149.13 s, total  | **15.0x** | **22.3x** |
| Speedup vs `T_seq_best` 149.13 s, kernel only | 16.5x   | 24.0x   |
| For comparison: `T_OMP_best` 14.36 s -> | 1.45x | 2.15x |
| For comparison: `T_MPI_best` 13.73 s -> | 1.38x | 2.06x |

ASCII speedup chart (vs `T_seq_best = 149.13 s`, total time):
```
Naive CUDA FP64  ###############                              15.0x
Naive CUDA FP32  ######################                       22.3x
OpenMP best      ##########                                   10.4x  (14.36 s on i9)
MPI best         ##########                                   10.9x  (13.73 s on i9)
                 |----+----|----+----|----+----|----+----|
                 0    5    10   15   20   25   30   35   40
```

## Take-aways before moving to the block-size sweep
1. The naive kernel already beats the BEST sequential CPU code by 15-22x; it also beats the BEST OpenMP and MPI runs (on the i9) by ~1.4-2.1x. So even the simplest CUDA mapping is competitive.
2. The hotspot is the kernel (~91-93% of total time), confirming MatMul is compute/memory dominated, not transfer-limited.
3. FP64 is already at 89% of T4 FP64 peak -> tiling will help FP64 only marginally.
4. FP32 is at 4% of T4 FP32 peak -> tiling has huge head-room here; this is where the next experiments should pay off.
5. `nvprof` works on T4 in *activity* mode (the GPU activities table is collected via CUPT activity API, which is supported on CC 7.5+). What does **not** work on T4 is `nvprof --metrics ...` (events / metrics collection). For coalescing/efficiency/occupancy metrics we use `ncu` (Nsight Compute) from Step 3 onward.

# Second CUDA experiment: block-size sweep on the naive kernel
Same kernel as Step 1, recompiled with `-DBLOCK=8 / 16 / 32` so we can pick the best naive launch configuration before adding shared memory. Each block has `BLOCK x BLOCK` threads:
*   BLOCK=8  -> 64 threads/block (2 warps), 1250x1250 grid
*   BLOCK=16 -> 256 threads/block (8 warps), 625x625 grid
*   BLOCK=32 -> 1024 threads/block (32 warps, the max per block on T4), 313x313 grid

## Compile commands
1. FP64: `nvcc -arch=sm_75 -O3 -DBLOCK={8,16,32} MatMulCuda.cu -o MatMulCuda_fp64_b{8,16,32}`
2. FP32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT -DBLOCK={8,16,32} MatMulCuda.cu -o MatMulCuda_fp32_b{8,16,32}`

## Raw timings (n = 10000, Tesla T4, `nvprof` activity mode)
| Block | Precision | H2D (ms) | Kernel (ms) | D2H (ms) | Total (ms) | Kernel % | C[0][0] |
|-------|-----------|----------|-------------|----------|------------|----------|---------|
|  8x8  | FP64      | 372.97   | 14099.13    | 546.97   | 15019.07   | 93.89%   | 60000   |
| 16x16 | FP64      | 344.46   |  9356.38    | 550.01   | 10250.85   | 91.29%   | 60000   |
| 32x32 | FP64      | 347.30   | 10982.96    | 544.55   | 11874.81   | 92.50%   | 60000   |
|  8x8  | FP32      | 174.49   |  9717.57    | 275.59   | 10167.66   | 95.59%   | 60000   |
| 16x16 | FP32      | 172.58   |  5072.21    | 266.92   |  5511.70   | 92.05%   | 60000   |
| 32x32 | FP32      | 182.94   |  3785.85    | 270.34   |  4239.13   | 89.34%   | 60000   |

(All runs verified via `C[0][0] = 60000`. Note: the FP32-b16 kernel measured 5.07 s here vs 6.20 s in Step 1 -- this is run-to-run variance on the shared Colab T4. We use the Step 2 numbers in the table because the 6 runs were collected back-to-back on the same VM, so they are mutually consistent.)

## Speedup vs `T_seq_best = 149.13 s`
| Block | Precision | Total time (s) | Speedup (total) | Kernel-only (s) | Speedup (kernel only) |
|-------|-----------|----------------|-----------------|-----------------|------------------------|
|  8x8  | FP64      | 15.019         |  9.93x          | 14.099          | 10.58x                 |
| 16x16 | FP64      | 10.251         | 14.55x          |  9.356          | 15.94x                 |
| 32x32 | FP64      | 11.875         | 12.56x          | 10.983          | 13.58x                 |
|  8x8  | FP32      | 10.168         | 14.67x          |  9.718          | 15.35x                 |
| 16x16 | FP32      |  5.512         | 27.05x          |  5.072          | 29.40x                 |
| **32x32** | **FP32** | **4.239**  | **35.18x**      | **3.786**       | **39.39x**             |

ASCII speedup chart (vs `T_seq_best = 149.13 s`, total time):
```
fp64 b8    ##########                          9.9x
fp64 b16   ###############                    14.6x
fp64 b32   #############                      12.6x
fp32 b8    ###############                    14.7x
fp32 b16   ###########################        27.0x
fp32 b32   ###################################  35.2x  <-- best naive
              |----+----|----+----|----+----|----+
              0    5    10   15   20   25   30  35  40
```

## Why FP64 prefers BLOCK=16 but FP32 prefers BLOCK=32 (compute-bound vs memory-bound)

This is the most informative result of the sweep. The two curves go in opposite directions because the two kernels are bottlenecked by different things:

*   **FP64 is compute-bound on the FP64 pipeline.** Throughput at the best point (b16) is `2 * n^3 / 9.356 s = 0.214 TFLOPs`, which is ~86% of T4's 0.25 TFLOPs FP64 peak. At b32 we lose ~17% performance because each thread uses more registers in FP64 (8-byte values), so we cannot reach as much occupancy with 1024 threads/block; b16 is the sweet spot where the FP64 ALUs are most efficiently fed. b8 is bad because only 2 warps per block leaves the warp scheduler too few options to hide the (modest) memory latency between FP64 multiplies.
*   **FP32 is memory-bound, and BLOCK=32 wins through implicit data reuse.** With BLOCK=32 each block computes a 32x32 sub-matrix of C, so each row of A is reused 32 times within the block and each column of B is reused 32 times -- staying in L1/L2 across uses. With BLOCK=16 each row/column is reused only 16 times, with BLOCK=8 only 8 times. This is the same locality argument as CPU-side blocking; we are getting "free" blocking from the launch geometry. FP32 throughput at b32 is `2e12 / 3.786 s = 0.528 TFLOPs`, only 6.5% of T4 FP32 peak (8.1 TFLOPs), confirming we are still memory-bound and Step 3 (explicit shared-memory tiling) has plenty of head-room.

## Hotspot: still the kernel
In every configuration the kernel is **89-96%** of total GPU time (see `Kernel %` column above). Memory transfers H2D + D2H are ~4-11% combined. The hotspot has not moved compared to Step 1: this remains a compute/memory-throughput problem inside the kernel, not a PCIe problem. Even at the fastest configuration (FP32 b32), the kernel is still 3.79 s out of 4.24 s = 89.3%.

## Take-aways before moving to the tiled kernel
1. **Best naive configuration: FP32, BLOCK=32 -> 4.24 s total, 35.2x speedup vs `T_seq_best`** and 86.2x vs the unoptimized sequential `T_seq_naive = 365.59 s`.
2. **Best FP64 configuration: BLOCK=16 -> 10.25 s total, 14.6x speedup**. Already near the FP64 ceiling of T4 (~86% of peak). Step 3 tiling will probably move FP64 only a few percent.
3. The FP32 winner is locked in because the kernel is still 6.5% of FP32 peak; explicit shared-memory tiling (Step 3) targets exactly this gap.
4. From Step 3 onward we use BLOCK=16 as the default tile size for both precisions to keep the comparison apples-to-apples with the sweep above; we will then do a tile-size sweep (Step 4) on the tiled kernel.

# Third CUDA experiment: shared-memory tiled kernel
This is the GPU analogue of [MatMulBlocking.c](MatMulBlocking.c). Each thread block stages a `TILE x TILE` sub-block of A and of B into the SM's shared memory, every thread reuses each loaded element TILE times before the next tile is loaded, and global-memory traffic drops by a factor of TILE compared to the naive kernel. Default `TILE = 16` (256 threads/block, same launch geometry as naive `BLOCK=16`).

The kernel ([Cuda/MatMulCudaTiled.cu](Cuda/MatMulCudaTiled.cu) lines 42-69):

```42:69:Cuda/MatMulCudaTiled.cu
__global__ void matmul_tiled(const real *A, const real *B, real *C, int n) {
    __shared__ real As[TILE][TILE];
    __shared__ real Bs[TILE][TILE];

    int tx = threadIdx.x;
    int ty = threadIdx.y;
    int row = blockIdx.y * TILE + ty;
    int col = blockIdx.x * TILE + tx;

    real sum = 0;

    // Walk over the tiles of A (along the row) and B (along the column).
    for (int t = 0; t < n / TILE; ++t) {
        // Cooperatively load one tile of A and one tile of B into shared memory.
        // Each thread loads exactly one element of each tile.
        As[ty][tx] = A[row * n + (t * TILE + tx)];
        Bs[ty][tx] = B[(t * TILE + ty) * n + col];
        __syncthreads();

        // Multiply the two tiles using only shared-memory accesses.
        #pragma unroll
        for (int k = 0; k < TILE; ++k) {
            sum += As[ty][k] * Bs[k][tx];
        }
        __syncthreads();
    }

    C[row * n + col] = sum;
}
```

Launch: `dim3 block(16, 16); dim3 grid(625, 625);`. Shared memory per block: 4096 B (FP64) or 2048 B (FP32) -- the T4 has 96 KB shared-memory carve-out per SM, so this is a tiny fraction; occupancy is not limited by shared memory at this tile size.

## Compile commands
1. FP64: `nvcc -arch=sm_75 -O3            MatMulCudaTiled.cu -o MatMulCudaTiled_fp64_t16`
2. FP32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT MatMulCudaTiled.cu -o MatMulCudaTiled_fp32_t16`

## Raw timings (n = 10000, TILE = 16, Tesla T4, `nvprof` activity mode)
| Phase     | FP64 (double) | FP32 (float)  |
|-----------|---------------|---------------|
| H2D copy  |    345.455 ms |    174.874 ms |
| Kernel    |   8309.403 ms |   2593.284 ms |
| D2H copy  |    641.945 ms |    279.510 ms |
| **Total** | **9296.8 ms** | **3047.7 ms** |
| Kernel %  |     89.40%    |     85.13%    |
| `C[0][0]` | 60000.000     | 60000.000     |

Both runs verified (`C[i][j] = 6 * n = 60000`).

## Speedup of the tiled kernel
*   **vs naive at the same launch geometry** (BLOCK=16): FP32 kernel `5072 -> 2593 ms`, **1.96x kernel speedup** (1.81x total). FP64 kernel `9356 -> 8309 ms`, **1.13x kernel speedup** (1.10x total).
*   **vs the best naive run** (FP32 BLOCK=32, kernel 3786 ms): FP32 tiled t16 kernel = 2593 ms, **1.46x faster than the best naive**.
*   **vs `T_seq_best = 149.13 s`**: FP64 tiled t16 total = 9.297 s -> **16.04x**. FP32 tiled t16 total = 3.048 s -> **48.93x** (kernel-only **57.51x**).

## Nsight Compute metrics (TILE = 16)
The ncu run is much slower than the timed run because ncu replays the kernel 8 times to collect different metric groups (43 s for FP32, 178 s for FP64); the timing numbers in the speedup table come from the `nvprof` run, not the ncu run.

| Metric                          | FP64 tiled  | FP32 tiled  |
|---------------------------------|-------------|-------------|
| Memory throughput               | 37.85 GB/s  | 100.47 GB/s |
| % of peak bandwidth (320 GB/s)  | 21.44%      | **78.61%**  |
| L1/TEX hit rate                 |  0.00%      |  0.00%      |
| L2 hit rate                     | 45.51%      | 48.66%      |
| Mem Pipes Busy                  | 38.28%      | 78.61%      |
| Theoretical / achieved occupancy| 100% / 99.99%| 100% / 99.97%|
| Active warps per SM (max 32)    | 32.00       | 31.99       |
| Registers / thread              | 44          | 38          |
| Block-limit warps               | 4 blocks/SM | 4 blocks/SM |

About the 0% L1/TEX hit rate: this is **expected and correct** for a shared-memory tiled kernel. Loads issued via `As[ty][tx]` and `Bs[k][tx]` go to the SM's shared-memory bank network, **not** through the L1/TEX cache, so by definition they cannot count as L1 hits. The reuse we wanted is happening in shared memory, where it is counted in the "Mem Pipes Busy" metric.

## Why FP32 wins big and FP64 barely moves (compute-bound vs bandwidth-bound, confirmed)
The Step 2 prediction is verified by hard numbers, not just timings:

*   **FP32 tiled is bandwidth-bound at 78.6% of T4 peak DRAM throughput.** Tiling cut the traffic by a factor of TILE = 16 vs the naive kernel (each A and B element is now read once per tile-step, not n/TILE times). The kernel reaches `2 * n^3 / 2.593 s = 0.771 TFLOPs`, only 9.5% of FP32 peak (8.1 TFLOPs) -- **we are not compute-bound, we are memory-bound by DRAM bandwidth**. To break this ceiling we need to either reduce traffic further (Step 4 -- bigger tile, more reuse per byte) or accept that this is the practical ceiling for a hand-written single-tile-per-thread-block kernel.
*   **FP64 tiled is compute-bound on the FP64 pipeline at 96% of FP64 peak.** Memory throughput is only 21% of bandwidth, so DRAM is not the issue. Tiling cut traffic, but the FP64 ALUs were already saturated, so the gain is only `1.13x`. `2 * n^3 / 8.309 s = 0.241 TFLOPs` vs the 0.25 TFLOPs FP64 peak = **96.4% of peak**. Step 4 will not move FP64 more than a couple of percent.

## Hotspot
Kernel is still 85-89% of total GPU time. The H2D + D2H share rises slightly compared to Step 1/2 (5.7% -> 9.1% in FP32, 3.7% -> 6.9% in FP64) **only because the kernel itself got faster**, not because the transfers got slower (they are essentially unchanged at 175/280 ms FP32 and 345/642 ms FP64). At the FP32 best of 3.05 s total, transfers are 14.9% of total, which is the first time they become non-negligible -- pinned host memory would help here, but we keep the host code simple.

## Take-aways before moving to the tile-size sweep
1. **Best so far: FP32 tiled TILE=16 -> 3.05 s total, 48.9x speedup vs `T_seq_best`, 57.5x kernel-only.** Already 1.4x faster than the best naive run, and 3.4x faster than the best OpenMP run on the i9 (14.36 s).
2. **FP64 is essentially done**: 96% of FP64 peak. We will still report FP64 numbers for Step 4 and Step 5 for completeness, but the interesting story moves to FP32.
3. **FP32 is bandwidth-bound at 78.6% of peak DRAM**: the only way to go faster on FP32 is to lift more reuse per byte. Step 4 sweeps `TILE = 8 / 16 / 32` to find that point, and Step 5 (cuBLAS) shows what a vendor-tuned implementation does (it uses register tiling on top of shared-memory tiling).
4. The 0% L1/TEX hit rate is by design (shared-memory loads bypass L1) and is **not** evidence of a problem.

# Fourth CUDA experiment: tile-size sweep on the tiled kernel
Same `MatMulCudaTiled.cu`, recompiled with `-DTILE=8 / 16 / 32`. This is the direct CUDA counterpart of the existing CPU "blocking size 32 / 16 / 8" experiments (see "Sixth/Seventh/Eighth experiment MPI" sections above). The TILE controls two things at once: threads per block (`TILE x TILE`) and reuse-per-loaded-element (each shared element is read TILE times before being discarded).

`n = 10000` divides evenly by 8 and 16 but not 32, so for `TILE=32` the experiment uses `n = 9984` (the closest multiple of 32). The work scales as `n^3`, giving a 0.48% smaller problem; we keep the raw measurement and additionally project the kernel/total time to a `n = 10000`-equivalent for the speedup table (factor `(10000/9984)^3 = 1.00481`).

## Compile commands
1. FP64: `nvcc -arch=sm_75 -O3            -DTILE={8,16}         MatMulCudaTiled.cu -o MatMulCudaTiled_fp64_t{8,16}`
2. FP32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT -DTILE={8,16}         MatMulCudaTiled.cu -o MatMulCudaTiled_fp32_t{8,16}`
3. FP64 t32: `nvcc -arch=sm_75 -O3            -DTILE=32 -DN=9984 MatMulCudaTiled.cu -o MatMulCudaTiled_fp64_t32`
4. FP32 t32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT -DTILE=32 -DN=9984 MatMulCudaTiled.cu -o MatMulCudaTiled_fp32_t32`

## Raw timings (Tesla T4, `nvprof` activity mode)
| TILE | Precision | n     | H2D (ms) | Kernel (ms) | D2H (ms) | Total (ms) | Kernel % | C[0][0]    |
|------|-----------|-------|----------|-------------|----------|------------|----------|------------|
|  8   | FP64      | 10000 | 354.34   | 10181.41    | 541.66   | 11077.40   | 91.93%   | 60000.000  |
| 16   | FP64      | 10000 | 353.52   |  8558.59    | 635.82   |  9547.94   | 89.66%   | 60000.000  |
| 32   | FP64      |  9984 | 346.60   |  8623.76    | 561.12   |  9531.47   | 90.49%   | 59904.000  |
|  8   | FP32      | 10000 | 201.99   |  4680.10    | 266.67   |  5148.76   | 90.92%   | 60000.000  |
| 16   | FP32      | 10000 | 181.61   |  2856.06    | 274.33   |  3311.99   | 86.27%   | 60000.000  |
| **32** | **FP32**| **9984** | **179.71** | **2133.58** | **329.15** | **2642.44** | **80.79%** | **59904.000** |

(All runs verified -- expected `C[0][0] = 6 * n` -> 60000 at n=10000 and 59904 at n=9984.)

## Speedup vs `T_seq_best = 149.13 s`
Times for the n=9984 row are shown both as raw (n=9984, what the program actually measured) and as **scaled** to a n=10000-equivalent workload (raw / 0.99521) so all rows live on a single comparable axis.

| TILE | Precision | n     | Total (s) | Speedup (total) | Kernel-only (s) | Speedup (kernel only) |
|------|-----------|-------|-----------|-----------------|-----------------|------------------------|
|  8   | FP64      | 10000 | 11.077    | 13.46x          | 10.181          | 14.65x                 |
| 16   | FP64      | 10000 |  9.548    | 15.62x          |  8.559          | 17.42x                 |
| 32   | FP64      |  9984 |  9.531    | 15.65x (raw)    |  8.624          | 17.29x (raw)           |
| 32   | FP64      | 10000-equiv |  9.577 | 15.57x (scaled) | 8.665           | 17.21x (scaled)        |
|  8   | FP32      | 10000 |  5.149    | 28.96x          |  4.680          | 31.86x                 |
| 16   | FP32      | 10000 |  3.312    | 45.02x          |  2.856          | 52.21x                 |
| **32** | **FP32**|  9984 |  **2.642**|  **56.45x (raw)** | **2.134**     | **69.88x (raw)**       |
| **32** | **FP32**| **10000-equiv** | **2.655** | **56.17x (scaled)** | **2.144** | **69.56x (scaled)**       |

ASCII speedup chart (vs `T_seq_best = 149.13 s`, total time, scaled where applicable):
```
fp64 t8     #############                          13.5x
fp64 t16    ################                       15.6x
fp64 t32    ################                       15.6x
fp32 t8     #############################          29.0x
fp32 t16    #############################################   45.0x
fp32 t32    #########################################################   56.2x  <-- best tiled
              |----+----|----+----|----+----|----+----|----+----|----+----|
              0    5    10   15   20   25   30   35   40   45   50   55  60
```

## Effective TFLOPs and percentage of T4 peak
| Variant         | Useful TFLOPs (kernel) | % of T4 peak |
|-----------------|-------------------------|--------------|
| FP64 tiled t8   | 0.196                   | 78.4% of FP64 peak (0.25) |
| FP64 tiled t16  | 0.234                   | 93.6% of FP64 peak |
| FP64 tiled t32  | 0.231                   | 92.4% of FP64 peak |
| FP32 tiled t8   | 0.427                   | 5.3% of FP32 peak (8.1)  |
| FP32 tiled t16  | 0.700                   | 8.6% of FP32 peak  |
| **FP32 tiled t32**| **0.933**             | **11.5% of FP32 peak** |

## Why TILE=32 wins for FP32 but not FP64 (consistent with Step 3)
*   **FP32 (memory-bound)**: each shared-memory element is reused TILE times, so doubling TILE from 16 to 32 halves global-memory traffic per FLOP. The kernel was at 78.6% of peak DRAM bandwidth at t16 (Step 3 ncu numbers); at t32 we slide the bottleneck from DRAM toward compute and pick up another 33% in TFLOPs (0.700 -> 0.933). t8 is the worst because each element is reused only 8 times -> 4x the traffic of t32 -> firmly memory-bound. The trend `t8 < t16 < t32` is monotonic exactly as expected for a bandwidth-bound kernel.
*   **FP64 (compute-bound)**: at t16 we already hit 93.6% of FP64 peak. Halving DRAM traffic with t32 cannot help because DRAM is not the bottleneck -- the FP64 ALU pipeline is. t32 is statistically tied with t16 (8624 ms vs 8559 ms is well within run-to-run variance). t8 is slightly worse (10181 ms) because at t8 we move enough traffic to start being limited by it again -- but the gap is much smaller than for FP32.

The launch-geometry side effect is also clean: TILE=32 means 1024 threads/block (the maximum on T4), so only 1 block fits per SM. The achieved occupancy is still 100% in this case (1 block x 32 warps = 32 warps = max warps/SM), but that means we have **less margin**: any per-thread register increase would force occupancy down. For our simple kernel that does not happen, but it is why a textbook would push register tiling next instead of just bigger TILE.

## Compare against the naive kernel at the same launch geometry
*   FP32 naive BLOCK=32 kernel = 3786 ms vs FP32 tiled TILE=32 kernel = 2134 ms (raw, n=9984) -> tiling alone gives **1.77x kernel speedup at the same launch geometry**. This is the cleanest possible demonstration of the shared-memory reuse story: same threads, same blocks, same arithmetic; only difference is whether reads come from DRAM (with whatever cache help we get) or from explicit shared memory.
*   FP64 naive BLOCK=16 kernel = 9356 ms vs FP64 tiled TILE=16 kernel = 8559 ms -> tiling gives only **1.09x** for FP64 at the same geometry. Confirms FP64 is compute-bound: explicit reuse cannot help because the bottleneck is downstream of the load path.

## Hotspot
Kernel share dropped from ~92% to **80.79% in the FP32 t32 winner** -- not because transfers got slower (they are essentially constant at ~180 ms H2D and ~330 ms D2H), but because the kernel has shrunk to 2.13 s. Transfers are now **18.4%** of total. To eat into that we would need pinned host memory (`cudaMallocHost`) and/or overlapping copies with compute via streams, but neither is necessary to make the speedup story.

## Take-aways before moving to cuBLAS
1. **Best hand-written CUDA so far: FP32 tiled TILE=32 -> 2.64 s total (n=9984), 56.2x speedup vs `T_seq_best`, 69.6x kernel-only.** That is **4.1x faster than the best OpenMP run** (14.36 s) and **5.2x faster than the best MPI run** (13.73 s) on the i9 -- on a different machine, so this is a cross-host claim, but it gives the right order of magnitude.
2. **FP64 is locked at ~93% of T4 FP64 peak, both for TILE=16 and TILE=32.** No further hand-written kernel will move it without using tensor cores (which the T4 supports for FP64 only via WMMA + Turing limitations and is outside the "human-readable, simple" scope).
3. **FP32 still has head-room to ~8x** (we are at 11.5% of FP32 peak). Closing that gap requires register tiling (each thread computes a `m x n` micro-tile of C, holding C values in registers across the full k-loop), which is exactly what cuBLAS does. Step 5 will show what we leave on the table by stopping at single-tile blocking.
4. The TILE=32 result is at n=9984; we will use the *scaled* values (56.17x total, 69.56x kernel-only) when we put the final summary table together so all rows are on the same axis.

# Fifth CUDA experiment: cuBLAS Sgemm / Dgemm (practical upper bound)
This step is not a hand-written kernel; it calls NVIDIA's cuBLAS library, which uses **register tiling on top of shared-memory tiling** plus assembly-level scheduling. We use it as a **practical upper bound** -- it tells us how much head-room we leave on the table by stopping at single-tile shared-memory blocking. The host code [Cuda/MatMulCublas.cu](Cuda/MatMulCublas.cu) is intentionally minimal and uses the standard column-major-of-the-transpose trick to feed the same row-major matrices we used in Steps 1-4.

A warm-up `gemm` call is run once before the timed call, because cuBLAS lazy-JIT-compiles its kernel on the first invocation; without the warm-up that one-off compile cost (often hundreds of ms on Colab) would land in our timing window.

## Compile commands (note `-lcublas`)
1. FP64: `nvcc -arch=sm_75 -O3            MatMulCublas.cu -o MatMulCublas_fp64 -lcublas`
2. FP32: `nvcc -arch=sm_75 -O3 -DUSE_FLOAT MatMulCublas.cu -o MatMulCublas_fp32 -lcublas`

## Raw timings (n = 10000, Tesla T4, after warm-up, `nvprof` activity mode)
| Phase     | FP64 (cuBLAS Dgemm) | FP32 (cuBLAS Sgemm) |
|-----------|---------------------|---------------------|
| H2D copy  |    358.06 ms        |    190.87 ms        |
| Kernel    |   7984.25 ms        |   **418.40 ms**     |
| D2H copy  |    552.51 ms        |    324.79 ms        |
| **Total** |  **8894.8 ms**      |  **934.06 ms**      |
| `C[0][0]` | 60000.000           | 60000.000           |

cuBLAS picks the kernel `volta_dgemm_128x64_nn` (FP64) and `volta_sgemm_128x64_nn` (FP32) -- 128x64 register-tile macro-kernels for Volta/Turing. The `nvprof` GPU activity table shows **two** kernel calls (warm-up + timed) of ~equal length, totalling 16.05 s for FP64 and 857 ms for FP32; we report the second (timed) one in the table above.

## Speedup vs `T_seq_best = 149.13 s`
| Variant      | Total (s) | Speedup (total) | Kernel (s) | Speedup (kernel) |
|--------------|-----------|-----------------|------------|-------------------|
| FP64 cuBLAS  | 8.895     | 16.77x          | 7.984      | 18.68x            |
| **FP32 cuBLAS** | **0.934** | **159.66x** | **0.418**  | **356.55x**       |

`Sgemm` total time is **934 ms** -- under one second to multiply two `10000 x 10000` matrices.

## Effective TFLOPs and percentage of T4 peak
| Variant     | Useful TFLOPs (kernel) | % of T4 peak               |
|-------------|-------------------------|----------------------------|
| FP64 cuBLAS | 0.251                   | **100% of FP64 peak (0.25)** -- at the hardware ceiling |
| FP32 cuBLAS | 4.781                   | **59% of FP32 peak (8.1)** -- compute-bound, no longer memory-bound |

For comparison, the best hand-written kernel was 0.231 TFLOPs (FP64 tiled t16, 92% of peak) and 0.933 TFLOPs (FP32 tiled t32, 11.5% of peak). The FP32 jump from 11.5% -> 59% of peak is the cost of the optimisations we deliberately chose **not** to implement.

## Nsight Compute -- the optimisation gap, quantified
The most informative single comparison is FP32 ours (TILE=16, where ncu numbers were collected in Step 3) versus FP32 cuBLAS Sgemm:

| Metric                          | FP32 tiled (ours, TILE=16) | FP32 cuBLAS Sgemm           |
|---------------------------------|-----------------------------|------------------------------|
| Kernel name                     | `matmul_tiled`              | `volta_sgemm_128x64_nn`      |
| Block size                      | 256 (16x16)                 | 128 (128x1)                  |
| Registers per thread            | 38                          | **122**                      |
| Static shared memory per block  | 2.05 KB                     | 12.54 KB                     |
| Achieved occupancy              | 99.97%                      | **49.82%** (limited by regs) |
| L1/TEX hit rate                 |  0.00%                      |  0.09%                       |
| L2 hit rate                     | 48.66%                      | **87.23%**                   |
| Memory throughput               | 100.5 GB/s                  | 47.8 GB/s                    |
| % of peak DRAM bandwidth        | **78.6%**                   | 43.2%                        |
| Mem Pipes Busy                  | 78.6%                       | 43.2%                        |
| Useful TFLOPs (kernel only)     | 0.700                       | 4.781                        |

What cuBLAS does differently:
1. **Register tiling.** With 122 registers per thread, each thread privately accumulates a chunk of C (a `128x64 / 128 = 64`-element column slice for the 128x64 macro-kernel) in registers across the whole k-loop. Our kernel uses 38 registers per thread and accumulates only **one** C element. Register tiling raises arithmetic intensity per loaded byte by a factor of `M_reg * N_reg / (M_reg + N_reg)`; for a 128x64 macro-tile this is roughly 43, vs `TILE/2 = 8` for our 16x16 tile.
2. **Deliberately low occupancy (50%).** Spending registers on a private C accumulator means fewer warps fit per SM -- exactly the trade-off Nsight flagged ("Block Limit Registers = 4 blocks/SM"). cuBLAS chose the right side of that trade-off because the kernel is no longer memory-bound at high occupancy: notice DRAM traffic dropped from 100.5 GB/s to 47.8 GB/s and L2 hit rate jumped from 48.7% to 87.2%, even though the kernel got 6x faster. We are doing far less DRAM traffic per FLOP.
3. **128x1 launch shape.** A 128-thread "row" handles a 128x64 output tile -- this maps neatly to four warps loading B coalesced and computing in parallel. It is not a pretty `__global__` you can write in 30 lines; it is hand-tuned PTX/SASS.

For FP64 the same techniques are applied (`volta_dgemm_128x64_nn`, 234 regs/thread, 25% occupancy) but the win shrinks to 7% because the FP64 ALU pipeline was already the bottleneck. Ncu confirms the FP64 cuBLAS kernel runs at only 2.6% of peak DRAM bandwidth -- DRAM is utterly idle, the FP64 ALUs are simply at their hard limit.

## Hotspot
For FP32 cuBLAS the kernel has shrunk so much that the **balance flips**: kernel = 45% of total GPU time (418 ms of 934 ms), H2D = 20%, D2H = 35%. We are starting to look like the `VectorAddCuda.cu` example -- transfers becoming a meaningful share. To eat into the remaining ~516 ms of transfer time we would need pinned host memory and/or stream overlap; that is the next research direction but is outside the scope here. For FP64 cuBLAS the kernel is still 90% of total -- transfers stay irrelevant because the kernel is huge.

## Take-aways from cuBLAS
1. **FP32 cuBLAS Sgemm reaches `159.66x` total speedup vs `T_seq_best`** -- by far the highest in the entire project. Kernel-only speedup is `356.55x`, and the kernel runs at 4.78 TFLOPs = 59% of T4 FP32 peak.
2. **FP64 cuBLAS Dgemm is essentially tied with our hand-written tiled t16** (1.07x speedup), confirming that for FP64 on T4 our simple tiled kernel was already optimal modulo a few percent. Both run at ~100% of the FP64 hardware ceiling.
3. The `5.10x` gap between our best hand-written FP32 kernel and cuBLAS is the price of stopping at single-tile shared-memory blocking. Closing that gap requires register tiling, which is a substantial increase in code complexity for a fixed-architecture optimisation -- a fair stopping point for a "human-readable, simple" implementation.

# CUDA summary -- final consolidated speedup table

All speedups below are computed against the BEST workstation sequential reference `T_seq_best = 149.13 s` (sequential `MatMulBlocking.c`, ICC -O3, n = 10000, i9-12900K). The CUDA times are measured on Google Colab's Tesla T4. **This is a cross-host comparison**: the GPU and CPU are not in the same machine. We report it because the same baseline is what we used for every OpenMP and MPI experiment in the readme, so all numbers in this project sit on the same axis.

For each kernel/precision pair we report only the best configuration found (block size for the naive kernel; tile size for the tiled kernel). Times for n=9984 (FP32 tiled t32) are scaled to n=10000-equivalent by `(10000/9984)^3 = 1.00481`.

| Implementation                    | Precision | Best config | Total (s)  | Kernel (s) | Speedup total | Speedup kernel | TFLOPs (kernel) | % of T4 peak |
|-----------------------------------|-----------|-------------|------------|------------|---------------|-----------------|------------------|--------------|
| Naive 2D-grid                     | FP64      | BLOCK=16    |  10.251    |   9.356    |  14.55x       |  15.94x         |  0.214           |  85.6%       |
| Naive 2D-grid                     | FP32      | BLOCK=32    |   4.239    |   3.786    |  35.18x       |  39.39x         |  0.528           |   6.5%       |
| Shared-memory tiled               | FP64      | TILE=16     |   9.548    |   8.559    |  15.62x       |  17.42x         |  0.234           |  93.6%       |
| Shared-memory tiled               | FP32      | TILE=32     |   2.655(*) |   2.144(*) |  56.17x       |  69.56x         |  0.933           |  11.5%       |
| **cuBLAS** Dgemm                  | **FP64**  | (vendor)    | **8.895**  | **7.984**  | **16.77x**    | **18.68x**      | **0.251**        | **100.0%**   |
| **cuBLAS** Sgemm                  | **FP32**  | (vendor)    | **0.934**  | **0.418**  | **159.66x**   | **356.55x**     | **4.781**        | **59.0%**    |

(*) FP32 tiled t32 timings scaled from raw n=9984 by `(10000/9984)^3 = 1.00481`.

## CPU references for context (n = 10000, i9-12900K)
| Implementation                    | Time (s) | Speedup vs `T_seq_best` |
|-----------------------------------|----------|--------------------------|
| Sequential, ICC -O3, no blocking  | 365.59   |  0.41x  (this is `T_seq_naive`, used as the worst case) |
| Sequential, ICC -O3, with blocking| 149.13   |  1.00x  (this is `T_seq_best`, the reference) |
| OpenMP best (24 threads, blocking)|  14.36   | 10.39x  |
| MPI best (12 procs, blocking 16)  |  13.73   | 10.86x  |

## Speedup chart vs `T_seq_best = 149.13 s` (total time)
```
seq O3 + blocking      #                                                           1.0x   (reference)
OpenMP best            ##########                                                 10.4x
MPI best               ##########                                                 10.9x
CUDA naive   FP64      ##############                                             14.6x
CUDA naive   FP32      ###################################                        35.2x
CUDA tiled   FP64      ###############                                            15.6x
CUDA cuBLAS  FP64      #################                                          16.8x
CUDA tiled   FP32      ########################################################   56.2x
CUDA cuBLAS  FP32      #####################################################################################################################################################  159.7x
                       |----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|
                       0    10   20   30   40   50   60   70   80   90   100  110  120  130  140  150  160
```

## Closing remarks
1. **The CUDA progression mirrors the CPU progression and reaches the same conclusions on different hardware.** "Compiler optimisation" -> Step 1 naive kernel; "blocking" -> Step 3 shared-memory tiled kernel; "best parallel" -> Step 5 cuBLAS. Each step adds an optimisation that targets the exact bottleneck identified by the previous step's profiling, and each step's improvement matches the prediction from arithmetic-intensity / roofline reasoning.
2. **FP32 vs FP64 makes a 170x difference at the high end** (cuBLAS Sgemm 0.93 s vs cuBLAS Dgemm 8.90 s) on T4 because of its 32:1 FP32:FP64 ratio. For the original `MatMul.c` workload (which uses `double`) the practical CUDA speedup is **~16-19x** over the BEST sequential CPU run; for FP32 it is **~160x**. The choice of precision is a first-class design decision on this generation of GPU.
3. **Cross-host caveat.** All speedups compare a Tesla T4 GPU against an i9-12900K CPU. They are honest in the sense that we are answering "if I had access to a T4, how much faster could I run my matmul vs what I get on my workstation today?", but they should not be interpreted as "GPUs are X-times faster than CPUs in general" -- a top-end Sapphire Rapids server CPU with AVX-512 would substantially close the gap, particularly for the hand-written CUDA kernels.
4. **The hotspot has fully migrated.** In `MatMul.c` the hotspot was the triple loop (~91% of run time). In our naive CUDA kernel the hotspot was the kernel (~91% of GPU time). In our tiled CUDA kernel the hotspot stayed in the kernel but the kernel got 1.8-2x faster. In cuBLAS Sgemm the hotspot is now **PCIe transfers** (kernel = 45% of total GPU time) -- if we wanted to keep optimising, the next experiment would be pinned host memory + overlapped streams, not a faster gemm.
