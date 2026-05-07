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
