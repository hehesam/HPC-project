# CUDA Implementation of MatMul -- Detailed Report

This report documents the CUDA stage of the HPC project: porting the matrix multiplication of [MatMul.c](../MatMul.c) to a GPU and progressively optimising it. Each sub-experiment is preceded by what we expect from the optimisation, followed by what we actually measured, what the profiler said, and what conclusion to carry into the next step.

The high-level summary table for the whole project lives in the main [readme.md](../readme.md). This report is the long-form, self-contained version of Stage 5.

---

## Table of contents

1. [Goal and methodology](#1-goal-and-methodology)
2. [Hardware](#2-hardware)
3. [Reference baseline](#3-reference-baseline)
4. [Background concepts](#4-background-concepts)
   - 4.1 [Why MatMul is interesting](#41-why-matmul-is-interesting)
   - 4.2 [Blocking on the CPU](#42-blocking-on-the-cpu)
   - 4.3 [Tiling on the GPU](#43-tiling-on-the-gpu-shared-memory)
   - 4.4 [cuBLAS](#44-cublas)
5. [Step 1 -- Naive CUDA kernel](#5-step-1--naive-cuda-kernel)
6. [Step 2 -- Block-size sweep](#6-step-2--block-size-sweep)
7. [Step 3 -- Shared-memory tiled kernel](#7-step-3--shared-memory-tiled-kernel)
8. [Step 4 -- Tile-size sweep](#8-step-4--tile-size-sweep)
9. [Step 5 -- cuBLAS reference](#9-step-5--cublas-reference)
10. [Final consolidation](#10-final-consolidation)
11. [Conclusions](#11-conclusions)

---

## 1. Goal and methodology

The CPU stages of this project showed that even on a 24-thread Intel i9-12900K with both OpenMP and MPI we plateau around 14 s for an n=10000 matmul. To push further we need either a different machine or a different programming model. We chose CUDA because:
- Matrix multiplication maps almost trivially onto a 2D thread grid (one thread per output element).
- The optimisation knobs (block size, shared-memory tiling, register tiling, vendor libraries) provide a clean, well-understood progression from "naive" to "production".
- Google Colab provides a free Tesla T4, so no local GPU is required.

The methodology mirrors the CPU stages exactly, in five sub-experiments:

| # | Sub-experiment             | What it tests                                          | Source file |
|---|----------------------------|--------------------------------------------------------|-------------|
| 1 | Naive CUDA                 | The most direct port of the C triple loop              | [MatMulCuda.cu](MatMulCuda.cu) |
| 2 | Block-size sweep           | Best launch configuration for the naive kernel         | (same file, `-DBLOCK=8/16/32`) |
| 3 | Shared-memory tiled kernel | GPU equivalent of CPU blocking                         | [MatMulCudaTiled.cu](MatMulCudaTiled.cu) |
| 4 | Tile-size sweep            | Best `TILE` for the tiled kernel                       | (same file, `-DTILE=8/16/32`) |
| 5 | cuBLAS reference           | Vendor-tuned upper bound (register tiling + assembly)  | [MatMulCublas.cu](MatMulCublas.cu) |

For each sub-experiment we run **both FP32 (`float`) and FP64 (`double`)** because the T4 has a 32:1 FP32:FP64 throughput ratio -- the precision choice changes the conclusions dramatically. The original `MatMul.c` uses `double`, so FP64 is the fair apples-to-apples comparison; FP32 shows how much head-room precision relaxation buys.

All speedups in this report are computed against the same reference as the rest of the project: `T_seq_best = 149.13 s` (sequential blocking, ICC `-O3`, n=10000, on the i9-12900K). This is a **cross-host** comparison (T4 GPU vs i9 CPU); we keep the same reference so the CUDA numbers sit on the same axis as Stages 1-4 of the main readme.

---

## 2. Hardware

### 2.1 Workstation (used for the CPU baseline only)

| Component | Detail |
|-----------|--------|
| CPU       | Intel i9-12900K, 12 cores / 24 threads, 3.20 GHz |
| OS        | Linux                                            |

### 2.2 Colab GPU (used for every CUDA experiment in this report)

| Component | Detail |
|-----------|--------|
| GPU                 | NVIDIA Tesla T4 (Turing, compute capability 7.5)        |
| GPU memory          | 16 GB GDDR6, 320 GB/s peak DRAM bandwidth               |
| FP32 peak throughput| ~8.1 TFLOPs (scalar, no tensor cores for `float`)       |
| FP64 peak throughput| ~0.25 TFLOPs (32x slower than FP32 -- a key constraint) |
| Streaming Multiprocessors | 40 SMs                                            |
| Max threads / block | 1024                                                    |
| Max threads / SM    | 1024 (-> max occupancy = 32 warps per SM)               |
| Shared memory / SM  | 96 KB carve-out (we use far less)                       |
| Driver / toolkit    | 580.82.07 / CUDA 13.0                                   |
| Host link           | PCIe 3.0 x16 (~12 GB/s peak)                            |

Why FP32:FP64 = 32:1 matters: every conclusion below depends on whether the kernel is **compute-bound** (FP64 case) or **memory-bound** (FP32 case). On most modern desktop/datacentre GPUs the ratio is 2:1 or 1:2; the T4 is unusual. For a "true" workstation GPU like an A100, FP64 would be 1/2 of FP32 and the FP64 story below would change.

### 2.3 Profiling tools used and their limitations on T4

* `nvprof` -- works in **activity mode** (collects kernel %, memcpy %, API call timings) on T4. **Does not work** with `--metrics ...` flags because metric/event collection was deprecated for compute capability >= 7.5.
* `ncu` (Nsight Compute) -- replaces the metric mode of `nvprof`. Used in this report for `gld_efficiency`, `gst_efficiency`, occupancy, L2 hit rate, memory throughput, register usage. It replays the kernel multiple times under instrumentation, so total wall-clock under `ncu` is much longer than the actual run -- only the *metrics* are relevant, never the timings.

---

## 3. Reference baseline

| Reference         | Time     | Source                                                       |
|-------------------|----------|--------------------------------------------------------------|
| `T_seq_naive`     | 365.59 s | [MatMul.c](../MatMul.c), ICC -O3, n=10000, on the i9         |
| **`T_seq_best`**  | **149.13 s** | [MatMulBlocking.c](../MatMulBlocking.c), ICC -O3, n=10000, on the i9 -- **the BEST sequential** |
| `T_OMP_best`      |  14.36 s | OpenMP + blocking, 24 threads, on the i9                     |
| `T_MPI_best`      |  13.73 s | MPI + blocking 16, 6 procs, on the i9                        |

All CUDA speedups in this report are `T_seq_best / T_CUDA = 149.13 / T_CUDA`.

---

## 4. Background concepts

### 4.1 Why MatMul is interesting

For an `n x n` matrix multiplication `C = A * B`:
- Useful work: `2 * n^3` floating-point operations (one mul + one add per inner-loop iteration).
- Useful data: `3 * n^2` matrix elements (A, B, C combined).
- "Arithmetic intensity" if you read everything once: `2 * n^3 / (3 * n^2 * sizeof(real))` = roughly `n / 12` for FP64.

But a *naive* implementation does **not** read each element once. The triple loop in `MatMul.c`:

```23:26:../MatMul.c
  for (i=0; i<n; ++i)
     for (k=0; k<n; k++)
        for (j=0; j<n; ++j)
           c[i][j] += a[i][k]*b[k][j];
```

re-reads each element of A from memory `n` times (once per `j`) and each element of B `n` times (once per `i`), unless cache reuse rescues us. Total memory traffic without cache help: `2 * n^3 * sizeof(real)` bytes for `2 * n^3` FLOPs, giving an effective arithmetic intensity of just **`1 / sizeof(real)`** = 0.125 FLOP/byte for FP64, 0.25 FLOP/byte for FP32.

For comparison, the T4 needs roughly **25 FLOP/byte** to keep its compute units busy from DRAM alone -- so unless we improve reuse, we stall waiting for memory and only a tiny fraction of the GPU is doing useful work. Every optimisation below is a different mechanism for **increasing reuse per loaded byte**.

### 4.2 Blocking on the CPU

In Stage 2 of the main project (`MatMulBlocking.c`) we tile the loops into chunks of size `B` so each loaded sub-matrix fits in L1/L2 cache. Once a `B x B` tile of A and a `B x B` tile of B are in cache, every element is reused `B` times before being evicted, which means we go from `2 * n^3` global reads down to `2 * n^3 / B` reads -- a `B`x reduction in memory traffic.

This single change took the n=10000 sequential run from `T_seq_naive = 365.59 s` to `T_seq_best = 149.13 s`, a 2.45x speedup with no parallelism added. It is the most important non-parallelism optimisation in the entire CPU stage of the project.

### 4.3 Tiling on the GPU (shared memory)

Blocking on a CPU is a *hint* to the cache subsystem. The cache *might* keep the tile resident if you access it densely enough. On a GPU we make the same idea explicit: each SM has a small (~96 KB on T4) on-chip scratch-pad called **shared memory** that is software-managed. We declare:

```cpp
__shared__ real As[TILE][TILE];
__shared__ real Bs[TILE][TILE];
```

Every thread in a block cooperatively loads one element of each tile (a `TILE x TILE` chunk of A and B) into shared memory, then all threads in the block reuse those tiles `TILE` times before the next tiles are loaded. The reuse story is the same as CPU blocking: `2 * n^3` global reads become `2 * n^3 / TILE` global reads.

Tiling is the GPU analogue of CPU blocking. Step 3 of this report measures it.

### 4.4 cuBLAS

Even GPU tiling has a ceiling: each thread still computes only **one** element of C. The next layer of optimisation is **register tiling** -- each thread privately holds a small `m x n` tile of C in *registers* across the whole k-loop, so each loaded value of A or B is reused not just `TILE` times across the block but `TILE * m * n / (m + n)` times in total. This dramatically increases reuse per loaded byte but uses a lot of registers and therefore reduces occupancy.

Writing register-tiled GEMM kernels by hand is a substantial engineering effort: the inner loop has to be unrolled, the register tile size has to be tuned per-architecture, and the load/store schedule has to be hand-optimised in PTX/SASS to hide latencies. NVIDIA ships the result as a closed-source library called **cuBLAS** (and an open-source meta-template called CUTLASS).

We use cuBLAS as a **practical upper bound** in Step 5 -- not as a hand-written kernel we are trying to match, but as a "what would NVIDIA do?" reference that quantifies how much we leave on the table by stopping at single-tile shared-memory blocking.

---

## 5. Step 1 -- Naive CUDA kernel

### 5.1 What it does

The most direct port of the C triple loop. Each CUDA thread computes one element `C[row][col]` and walks the entire `k`-loop itself. No shared memory, no cleverness.

```36:46:MatMulCuda.cu
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

Launch: `dim3 block(16, 16); dim3 grid(625, 625);` -> 256 threads per block, 100,000,000 threads in total (one per output element).

The same source compiles to FP64 (default) or FP32 (with `-DUSE_FLOAT`):
```
nvcc -arch=sm_75 -O3                MatMulCuda.cu -o MatMulCuda_fp64
nvcc -arch=sm_75 -O3 -DUSE_FLOAT    MatMulCuda.cu -o MatMulCuda_fp32
```

### 5.2 Measured timings (n = 10000, BLOCK = 16, T4)

| Phase     | FP64           | FP32           |
|-----------|----------------|----------------|
| H2D copy  |    380.87 ms   |    172.94 ms   |
| Kernel    |   9018.17 ms   |   6200.31 ms   |
| D2H copy  |    531.39 ms   |    301.30 ms   |
| **Total** | **9930.4 ms**  | **6674.6 ms**  |
| Kernel %  |  90.8%         |  92.9%         |

`C[0][0] = 60000` in both cases (= `6 * n` -- correct).

### 5.3 Hotspot analysis

The kernel dominates total GPU time in both precisions (~91-93%). This is the **opposite** of the textbook `vector_add` example, where memcpy dominates. MatMul has `O(n^3)` work for `O(n^2)` data, so as soon as `n` is large enough the compute side eclipses the transfers. PCIe bandwidth is therefore not the problem we need to solve.

### 5.4 Vectorisation / coalescing analysis (analytical, since `nvprof --metrics` is unavailable on T4)

A warp on T4 is 32 threads. With `block(16,16)` a warp covers `threadIdx.x = 0..15, threadIdx.y = 0..1`, so within one warp `col` takes 16 distinct values and `row` takes 2.

* `A[row * n + k]` -- 2 unique row values per warp, `k` is loop-invariant within the warp -> 2 cache lines loaded per inner-loop step. Decent.
* `B[k * n + col]` -- 16 distinct columns per warp, `k` invariant -> 16 contiguous elements (= one or two 128 B sectors). **Coalesced**.
* The real problem is **reuse across blocks**, not coalescing within a block: each element of A is reloaded by every block in its column-strip, each element of B by every block in its row-strip. Total memory traffic is `2 * n^3 * sizeof(real)` reads -> arithmetic intensity = `1 / sizeof(real)` = 0.125 FLOP/byte for FP64 -- exactly the same low value as the unblocked CPU code.

This is the same "every B column re-read for every i" cache-miss problem that `MatMulBlocking.c` solved on the CPU. Step 3 fixes it on the GPU.

### 5.5 Effective performance vs T4 peak

| Variant   | Useful TFLOPs (kernel) | % of T4 peak |
|-----------|-------------------------|--------------|
| FP64 naive| `2e12 / 9.018 = 0.222` | **89% of FP64 peak (0.25)** -- already near the FP64 ceiling |
| FP32 naive| `2e12 / 6.200 = 0.323` |  4% of FP32 peak (8.1)    -- huge head-room                     |

This is the central observation of the whole CUDA stage: **FP64 is already nearly at the hardware ceiling even with the naive kernel**, while **FP32 has room to grow by an order of magnitude**. The two precisions tell different stories for the rest of the report.

### 5.6 Speedup vs `T_seq_best = 149.13 s`

| Metric                          | FP64  | FP32  |
|---------------------------------|-------|-------|
| Total time                      | 9.93 s | 6.67 s |
| Speedup vs `T_seq_best` (total) | **15.0x** | **22.3x** |
| Speedup vs `T_seq_naive` 365.59 s | 36.8x | 54.8x |
| For comparison: vs OpenMP best 14.36 s | 1.45x | 2.15x |
| For comparison: vs MPI best 13.73 s    | 1.38x | 2.06x |

The naive CUDA kernel **already beats every CPU experiment in the project**, and we have not done a single optimisation yet.

---

## 6. Step 2 -- Block-size sweep

### 6.1 What it does

Same naive kernel, recompiled with `-DBLOCK=8 / 16 / 32` to find the best launch configuration before adding shared memory.

| BLOCK | Threads/block | Warps/block | Grid       |
|-------|---------------|-------------|------------|
|  8    |  64           |  2          | 1250x1250  |
| 16    | 256           |  8          |  625x625   |
| 32    | 1024 (max)    | 32          |  313x313   |

### 6.2 Measured timings (n = 10000, T4, `nvprof` activity mode)

| Block | Precision | Kernel (ms) | Total (ms) | Kernel % |
|-------|-----------|-------------|------------|----------|
|  8x8  | FP64      | 14099.1     | 15019.1    | 93.9%    |
| 16x16 | FP64      |  9356.4     | 10250.9    | 91.3%    |
| 32x32 | FP64      | 10983.0     | 11874.8    | 92.5%    |
|  8x8  | FP32      |  9717.6     | 10167.7    | 95.6%    |
| 16x16 | FP32      |  5072.2     |  5511.7    | 92.1%    |
| **32x32** | **FP32** |  **3785.9** |  **4239.1** | **89.3%** |

### 6.3 Speedup vs `T_seq_best = 149.13 s`

| Block | Precision | Speedup (total) |
|-------|-----------|-----------------|
|  8x8  | FP64      |  9.93x          |
| 16x16 | FP64      | **14.55x**      |
| 32x32 | FP64      | 12.56x          |
|  8x8  | FP32      | 14.67x          |
| 16x16 | FP32      | 27.05x          |
| **32x32** | **FP32** | **35.18x**   |

### 6.4 Why FP64 prefers BLOCK=16 but FP32 prefers BLOCK=32

The two curves go in **opposite directions**, and that is the most informative result of the sweep:

* **FP64 is compute-bound on the FP64 pipeline.** At BLOCK=16 we hit 86% of the T4's FP64 peak; at BLOCK=32 each thread uses more registers (FP64 values are 8 bytes), so we lose ~17% to register pressure and reduced occupancy. BLOCK=8 is bad because only 2 warps per block leaves the warp scheduler too few options to hide memory latency between FP64 multiplies.
* **FP32 is memory-bound, and BLOCK=32 wins through implicit data reuse.** With BLOCK=32 each block computes a 32x32 sub-matrix of C, so each row of A is reused 32 times within the block and each column of B is reused 32 times -- with hardware caching (L1/L2) this is "free" partial blocking. With BLOCK=8 each row/column is reused only 8 times. This is exactly the same locality argument as CPU blocking, but driven entirely by launch geometry.

This split between "FP64 compute-bound" and "FP32 memory-bound" governs the rest of the report.

### 6.5 Take-aways

* Best naive: **FP32 BLOCK=32 -> 4.24 s, 35.2x speedup**.
* Best naive FP64: **BLOCK=16 -> 10.25 s, 14.6x speedup** (already 86% of FP64 peak).
* The kernel is still 89-96% of total GPU time -- the hotspot has not moved.

---

## 7. Step 3 -- Shared-memory tiled kernel

### 7.1 What it does

The GPU analogue of `MatMulBlocking.c`. Each thread block stages a `TILE x TILE` sub-block of A and of B into the SM's shared memory, every thread reuses each loaded element TILE times before the next tile is loaded, and global-memory traffic drops by a factor of TILE compared to the naive kernel.

```42:69:MatMulCudaTiled.cu
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

Step 3 uses `TILE = 16` -- same launch geometry as naive `BLOCK=16`, so the comparison is apples-to-apples. The only difference is that this kernel reads each A/B element from global memory **once per tile-step**, not n times.

### 7.2 Measured timings (n = 10000, TILE = 16, T4)

| Phase     | FP64           | FP32           |
|-----------|----------------|----------------|
| H2D copy  |    345.46 ms   |    174.87 ms   |
| Kernel    |   8309.40 ms   |   2593.28 ms   |
| D2H copy  |    641.95 ms   |    279.51 ms   |
| **Total** | **9296.8 ms**  | **3047.7 ms**  |
| Kernel %  |  89.4%         |  85.1%         |

### 7.3 Speedup of the tiled kernel

* **vs naive at the same launch geometry (BLOCK/TILE=16):**
  * FP32 kernel `5072 -> 2593 ms`, **1.96x kernel speedup**.
  * FP64 kernel `9356 -> 8309 ms`, **1.13x kernel speedup**.
* **vs the best naive run (FP32 BLOCK=32, kernel 3786 ms):**
  * FP32 tiled t16 kernel = 2593 ms, **1.46x faster than the best naive**.
* **vs `T_seq_best = 149.13 s`:**
  * FP64 tiled total = 9.30 s -> **16.04x**.
  * FP32 tiled total = 3.05 s -> **48.93x** (kernel-only **57.51x**).

### 7.4 Nsight Compute metrics (the proof of *why* it works)

| Metric                          | FP64 tiled  | FP32 tiled  |
|---------------------------------|-------------|-------------|
| Memory throughput               | 37.85 GB/s  | 100.47 GB/s |
| % of T4 peak DRAM bandwidth     | 21.4%       | **78.6%**   |
| L1/TEX hit rate                 |  0.0%       |  0.0%       |
| L2 hit rate                     | 45.5%       | 48.7%       |
| Mem Pipes Busy                  | 38.3%       | 78.6%       |
| Theoretical / achieved occupancy| 100% / 99.99%| 100% / 99.97%|
| Active warps per SM (max 32)    | 32.00       | 31.99       |
| Registers / thread              | 44          | 38          |

Two observations worth highlighting:

* The **0% L1/TEX hit rate is by design**. Loads issued via `As[ty][tx]` and `Bs[k][tx]` go to the SM's shared-memory bank network, not through the L1/TEX cache, so by definition they cannot count as L1 hits. The reuse we wanted is happening in shared memory, where it is counted as "Mem Pipes Busy".
* **FP32 hits 78.6% of peak DRAM bandwidth** -- the kernel is now firmly bandwidth-bound. To go further on FP32 we either reduce DRAM traffic still more (Step 4) or accept this as the practical ceiling for single-tile blocking.

### 7.5 Effective performance vs T4 peak

| Variant   | Useful TFLOPs (kernel) | % of T4 peak |
|-----------|-------------------------|--------------|
| FP64 tiled| 0.241                   | **96.4% of FP64 peak** (was 89% in Step 1) |
| FP32 tiled| 0.771                   | 9.5% of FP32 peak (was 4% in Step 1)        |

FP64 is essentially at the FP64 hardware ceiling. FP32 is now bandwidth-bound, not compute-bound, but still has 10x of headroom in raw FLOPs.

### 7.6 Take-aways

* Tiling targets reuse, not occupancy. FP32 wins big (~2x kernel speedup) because it was bandwidth-bound; FP64 wins very little (~13%) because it was compute-bound.
* This is the GPU equivalent of the 2.45x speedup that CPU blocking gave us in Stage 2 -- the same idea, applied to a very different memory hierarchy.

---

## 8. Step 4 -- Tile-size sweep

### 8.1 What it does

Same `MatMulCudaTiled.cu`, recompiled with `-DTILE=8 / 16 / 32`. The TILE parameter controls two things at once: threads per block (`TILE x TILE`) and reuse-per-loaded-element (each shared element is read TILE times before being discarded). This is the direct CUDA counterpart of the existing CPU "blocking size 32 / 16 / 8" experiments in the main readme.

`n = 10000` divides evenly by 8 and 16 but **not by 32**, so for `TILE=32` the experiment uses `n = 9984` (closest multiple of 32). The work scales as `n^3`, giving a 1.5% smaller problem; we keep the raw measurement and additionally project to a `n=10000`-equivalent for the speedup table (factor `(10000/9984)^3 = 1.00481`).

### 8.2 Measured timings (T4)

| TILE | Precision | n     | Kernel (ms) | Total (ms) | Kernel % |
|------|-----------|-------|-------------|------------|----------|
|  8   | FP64      | 10000 | 10181.4     | 11077.4    | 91.9%    |
| 16   | FP64      | 10000 |  8558.6     |  9547.9    | 89.7%    |
| 32   | FP64      |  9984 |  8623.8     |  9531.5    | 90.5%    |
|  8   | FP32      | 10000 |  4680.1     |  5148.8    | 90.9%    |
| 16   | FP32      | 10000 |  2856.1     |  3312.0    | 86.3%    |
| **32**   | **FP32**  |  **9984** |  **2133.6** |  **2642.4** | **80.8%** |

### 8.3 Speedup vs `T_seq_best = 149.13 s`

| TILE | Precision | n     | Total (s) | Speedup (total)        |
|------|-----------|-------|-----------|------------------------|
|  8   | FP64      | 10000 | 11.077    | 13.46x                 |
| 16   | FP64      | 10000 |  9.548    | 15.62x                 |
| 32   | FP64      |  9984 |  9.531    | 15.65x (raw) / 15.57x (scaled) |
|  8   | FP32      | 10000 |  5.149    | 28.96x                 |
| 16   | FP32      | 10000 |  3.312    | 45.02x                 |
| **32**| **FP32**  |  **9984** | **2.642** | **56.45x (raw) / 56.17x (scaled)** |

Best so far: **FP32 TILE=32 -> 2.65 s scaled, 56.17x speedup**.

### 8.4 Why TILE=32 wins for FP32 but not for FP64

* **FP32 is memory-bound**, so doubling TILE from 16 to 32 halves global-memory traffic per FLOP. This pushes the kernel from 78.6% of peak DRAM bandwidth (Step 3 ncu) toward more compute-bound territory and picks up another 33% in TFLOPs (0.700 -> 0.933). The trend `t8 < t16 < t32` is monotonic exactly as expected for a bandwidth-bound kernel.
* **FP64 is compute-bound**, so halving DRAM traffic at TILE=32 cannot help -- DRAM is not the bottleneck. `t16 = 8559 ms` and `t32 = 8624 ms` are statistically tied; t8 is slightly worse only because it generates enough extra traffic to start being limited by bandwidth too.

### 8.5 Effective performance vs T4 peak

| Variant         | Useful TFLOPs (kernel) | % of T4 peak |
|-----------------|-------------------------|--------------|
| FP64 tiled t16  | 0.234                   | 93.6% of FP64 peak |
| FP64 tiled t32  | 0.231                   | 92.4% of FP64 peak |
| FP32 tiled t8   | 0.427                   | 5.3% of FP32 peak  |
| FP32 tiled t16  | 0.700                   | 8.6% of FP32 peak  |
| **FP32 tiled t32** | **0.933**            | **11.5% of FP32 peak** |

### 8.6 Hotspot has shifted slightly

For the FP32 t32 winner the kernel has shrunk to 2.13 s, so transfers are now **18.4%** of total (vs 7-9% in earlier steps). This is the first time PCIe transfers become non-trivial in the CUDA stage. Eating into them would require pinned host memory (`cudaMallocHost`) or stream overlap; neither is necessary to make the speedup story but both are obvious next steps.

### 8.7 Take-aways

* **Best hand-written CUDA: FP32 tiled TILE=32 -> 2.65 s, 56.2x speedup**.
* FP64 is locked at ~93% of T4 FP64 peak; no further hand-written kernel will move it without using tensor cores (T4's tensor cores accelerate FP16/INT8 mainly, not plain FP64).
* FP32 still has ~8x headroom in raw TFLOPs (we are at 11.5% of FP32 peak). Closing that gap requires register tiling, which is exactly what cuBLAS does in Step 5.

---

## 9. Step 5 -- cuBLAS reference

### 9.1 What it does

Calls cuBLAS' production `cublasSgemm` (FP32) or `cublasDgemm` (FP64) on the same matrices. We use it as a **practical upper bound** for what register-tiled, vendor-optimised assembly does on T4.

Two implementation details:
1. cuBLAS is **column-major**, our matrices are row-major. Computing `C^T = B^T * A^T` in column-major is bit-identical to `C = A * B` in row-major; for square `n x n` matrices this is a one-line trick (swap the operands and tell cuBLAS no transpose).
2. cuBLAS **lazy-JITs** its kernel on the first invocation. We do one warm-up gemm (untimed) before the timed call to keep that one-off cost out of the measurement window.

```bash
nvcc -arch=sm_75 -O3            MatMulCublas.cu -o MatMulCublas_fp64 -lcublas
nvcc -arch=sm_75 -O3 -DUSE_FLOAT MatMulCublas.cu -o MatMulCublas_fp32 -lcublas
```

### 9.2 Measured timings (n = 10000, T4, after warm-up)

| Phase     | FP64 (cublasDgemm) | FP32 (cublasSgemm) |
|-----------|--------------------|--------------------|
| H2D copy  |    358.06 ms       |    190.87 ms       |
| Kernel    |   7984.25 ms       |    **418.40 ms**   |
| D2H copy  |    552.51 ms       |    324.79 ms       |
| **Total** |  **8894.8 ms**     |   **934.06 ms**    |

cuBLAS picks `volta_dgemm_128x64_nn` (FP64) and `volta_sgemm_128x64_nn` (FP32) -- 128x64 register-tile macro-kernels for Volta/Turing.

### 9.3 Speedup vs `T_seq_best = 149.13 s`

| Variant      | Total (s) | Speedup (total) | Kernel (s) | Speedup (kernel) |
|--------------|-----------|-----------------|------------|-------------------|
| FP64 cuBLAS  | 8.895     | 16.77x          | 7.984      | 18.68x            |
| **FP32 cuBLAS** | **0.934** | **159.66x** | **0.418**  | **356.55x**       |

Sgemm runs the entire n=10000 matmul in **under one second**.

### 9.4 Effective performance vs T4 peak

| Variant     | Useful TFLOPs (kernel) | % of T4 peak                                         |
|-------------|-------------------------|------------------------------------------------------|
| FP64 cuBLAS | 0.251                   | **100% of FP64 peak (0.25)** -- at the hardware ceiling |
| FP32 cuBLAS | 4.781                   | **59.0% of FP32 peak (8.1)** -- compute-bound, no longer memory-bound |

### 9.5 The optimisation gap vs our hand-written kernel, quantified

The most informative single comparison is **FP32 ours (TILE=16) vs FP32 cuBLAS Sgemm**, both profiled with Nsight Compute:

| Metric                     | FP32 tiled (ours) | FP32 cuBLAS Sgemm |
|----------------------------|--------------------|--------------------|
| Block size                 | 256 (16x16)        | 128 (128x1)        |
| Registers per thread       | 38                 | **122**            |
| Shared memory per block    | 2.05 KB            | 12.54 KB           |
| Achieved occupancy         | 99.97%             | **49.82%** (deliberately low) |
| L2 hit rate                | 48.7%              | **87.2%**          |
| Memory throughput          | 100.5 GB/s         | 47.8 GB/s          |
| % of peak DRAM bandwidth   | **78.6%**          | 43.2%              |
| Useful TFLOPs (kernel)     | 0.700              | **4.781**          |

What cuBLAS does differently:

1. **Register tiling.** With 122 registers per thread, each thread privately accumulates a chunk of C across the entire k-loop. Our kernel uses 38 registers and accumulates only one C element. Register tiling raises arithmetic intensity per loaded byte by a factor of `M_reg * N_reg / (M_reg + N_reg)`; for a 128x64 macro-tile this is roughly 43, vs `TILE/2 = 8` for our 16x16 tile.
2. **Deliberately low occupancy (50%).** Spending registers on a private C accumulator means fewer warps fit per SM. Nsight even flags this as a "performance opportunity" -- but it is the right trade-off here, as the 6x kernel speedup proves. The kernel is no longer memory-bound at this lower occupancy: DRAM traffic dropped from 100.5 GB/s to 47.8 GB/s, L2 hit rate jumped from 49% to 87%, even while the kernel got 6x faster. We are doing far less DRAM traffic per FLOP.
3. **128x1 launch shape.** A 128-thread "row" handles a 128x64 output tile -- this maps neatly to four warps loading B coalesced and computing in parallel. It is not a kernel you can write in 30 readable lines; it is hand-tuned PTX/SASS.

For FP64 the same techniques are applied (`volta_dgemm_128x64_nn`, 234 regs/thread, 25% occupancy) but the win shrinks to 7% because the FP64 ALU pipeline was already the bottleneck.

### 9.6 Hotspot has fully migrated for FP32

For FP32 cuBLAS the kernel = 45% of total GPU time (418 ms of 934 ms), H2D = 20%, D2H = 35%. We now look like the textbook `vector_add` example: **the kernel is no longer the hotspot, PCIe transfers are**. To eat into the remaining ~516 ms of transfer time we would need pinned host memory and/or stream overlap. For FP64 the kernel is still 90% of total -- transfers stay irrelevant because the kernel is huge.

### 9.7 Take-aways

* **FP32 cuBLAS Sgemm: 159.66x total speedup vs `T_seq_best`** -- by far the highest in the entire project.
* **FP64 cuBLAS Dgemm: only 1.07x faster than our hand-written tiled t16**. This validates that for FP64 on T4 our simple tiled kernel was already near-optimal; both run at ~100% of the FP64 hardware ceiling.
* The 5.10x gap between our best hand-written FP32 kernel and cuBLAS quantifies what **register tiling** buys -- a substantial increase in code complexity for a fixed-architecture optimisation, which is a fair stopping point for a "human-readable, simple" implementation.

---

## 10. Final consolidation

For each kernel/precision pair the table below reports only the best configuration found. Times for n=9984 (FP32 tiled t32) are scaled to n=10000-equivalent.

| Implementation                | Precision | Best config | Total (s)  | Kernel (s) | Speedup total | Speedup kernel | TFLOPs (kernel) | % of T4 peak |
|-------------------------------|-----------|-------------|------------|------------|---------------|-----------------|------------------|--------------|
| Naive 2D-grid                 | FP64      | BLOCK=16    | 10.251     |  9.356     |  14.55x       |  15.94x         | 0.214            |  85.6%       |
| Naive 2D-grid                 | FP32      | BLOCK=32    |  4.239     |  3.786     |  35.18x       |  39.39x         | 0.528            |   6.5%       |
| Shared-memory tiled           | FP64      | TILE=16     |  9.548     |  8.559     |  15.62x       |  17.42x         | 0.234            |  93.6%       |
| Shared-memory tiled           | FP32      | TILE=32 (*) |  2.655     |  2.144     |  56.17x       |  69.56x         | 0.933            |  11.5%       |
| **cuBLAS Dgemm**              | **FP64**  | (vendor)    | **8.895**  | **7.984**  | **16.77x**    | **18.68x**      | **0.251**        | **100.0%**   |
| **cuBLAS Sgemm**              | **FP32**  | (vendor)    | **0.934**  | **0.418**  | **159.66x**   | **356.55x**     | **4.781**        | **59.0%**    |

(*) FP32 tiled t32 timings scaled from raw n=9984 by `(10000/9984)^3 = 1.00481`.

### 10.1 CPU references for context (n = 10000, on the i9-12900K, from Stages 1-4 of the main readme)

| Implementation                    | Time (s) | Speedup vs `T_seq_best` |
|-----------------------------------|----------|--------------------------|
| Sequential, ICC -O3, no blocking  | 365.59   |  0.41x  (= `T_seq_naive`)|
| Sequential, ICC -O3, with blocking| 149.13   |  1.00x  (= `T_seq_best`) |
| OpenMP best (24 threads, blocking)|  14.36   | 10.39x                   |
| MPI best (12 procs, blocking 16)  |  13.73   | 10.86x                   |

### 10.2 Speedup chart (vs `T_seq_best = 149.13 s`, total time)

```
seq O3 + blocking      #                                                                                         1.0x   (reference)
OpenMP best            ##########                                                                               10.4x
MPI best               ##########                                                                               10.9x
CUDA naive   FP64      ##############                                                                           14.6x
CUDA naive   FP32      ###################################                                                      35.2x
CUDA tiled   FP64      ###############                                                                          15.6x
CUDA cuBLAS  FP64      #################                                                                        16.8x
CUDA tiled   FP32      ########################################################                                 56.2x
CUDA cuBLAS  FP32      ###########################################################################################################################################################  159.7x
                       |----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|----+----|
                       0    10   20   30   40   50   60   70   80   90   100  110  120  130  140  150  160
```

---

## 11. Conclusions

1. **The CUDA progression mirrors the CPU progression and lands the same conclusions on different hardware.**  Compiler optimisation -> Step 1 naive kernel; CPU blocking -> Step 3 shared-memory tiled kernel; vendor-tuned BLAS -> Step 5 cuBLAS. Each step adds an optimisation that targets the exact bottleneck identified by the previous step's profiling, and each step's improvement matches the prediction from arithmetic-intensity / roofline reasoning.
2. **FP32 vs FP64 makes a 170x difference at the high end** (cuBLAS Sgemm 0.93 s vs cuBLAS Dgemm 8.90 s) on T4 because of its 32:1 FP32:FP64 ratio. For the original `MatMul.c` workload (which uses `double`) the practical CUDA speedup is **~16-19x** over the BEST sequential CPU run; for FP32 it is **~160x**. Choice of precision is a first-class design decision on this generation of GPU.
3. **Cross-host caveat.** All speedups compare a Tesla T4 GPU against an i9-12900K CPU. They are honest answers to "if I had access to a T4, how much faster could I run my matmul vs my workstation today?", but they should not be interpreted as "GPUs are X-times faster than CPUs in general" -- a top-end Sapphire Rapids CPU with AVX-512 and MKL would substantially close the gap.
4. **The hotspot has fully migrated.**
   * In `MatMul.c` the hotspot was the triple loop (~91% of run time).
   * In our naive CUDA kernel the hotspot was the kernel (~91% of GPU time).
   * In our tiled CUDA kernel the kernel got 1.8-2x faster but stayed the hotspot (85-90%).
   * In cuBLAS Sgemm the hotspot is now **PCIe transfers** (kernel = 45% of total). If we wanted to keep optimising, the next experiment would be pinned host memory + overlapped streams, not a faster gemm.
5. **Hand-written tiling closes most of the gap; cuBLAS closes the rest.** Our best hand-written FP32 kernel is 56x faster than `T_seq_best`. cuBLAS reaches 159x. The ~3x remaining gap is the price of register tiling -- a well-known optimisation that exchanges occupancy for reuse-per-loaded-byte and crosses the boundary from "human-readable, simple" code into hand-tuned PTX/SASS.
