// Step 3: Shared-memory tiled CUDA matrix multiplication.
// GPU analogue of MatMulBlocking.c on the CPU side: each thread block
// loads a TILE x TILE sub-block of A and of B into shared memory, then
// every thread in the block reuses each loaded element TILE times before
// the next tile is loaded. This drops global-memory traffic by a factor
// of TILE compared to the naive kernel.
//
// Compile:
//   FP64, TILE=16: nvcc -arch=sm_75 -O3                           MatMulCudaTiled.cu -o MatMulCudaTiled_fp64_t16
//   FP32, TILE=16: nvcc -arch=sm_75 -O3 -DUSE_FLOAT                MatMulCudaTiled.cu -o MatMulCudaTiled_fp32_t16
//   FP32, TILE=32: nvcc -arch=sm_75 -O3 -DUSE_FLOAT -DTILE=32      MatMulCudaTiled.cu -o MatMulCudaTiled_fp32_t32

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#ifndef N
#define N 10000        // n must be divisible by TILE for this simple version
#endif

#ifndef TILE
#define TILE 16        // tile side; threads per block = TILE * TILE
#endif

#ifdef USE_FLOAT
typedef float real;
#define DTYPE_NAME "float (FP32)"
#else
typedef double real;
#define DTYPE_NAME "double (FP64)"
#endif

#define CUDA_CHECK(call) do {                                          \
    cudaError_t err = (call);                                          \
    if (err != cudaSuccess) {                                          \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                      \
                __FILE__, __LINE__, cudaGetErrorString(err));          \
        exit(1);                                                       \
    }                                                                  \
} while (0)

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

int main(void) {
    const int n = N;
    const size_t bytes = (size_t)n * n * sizeof(real);

    if (n % TILE != 0) {
        fprintf(stderr, "ERROR: N=%d must be divisible by TILE=%d\n", n, TILE);
        return 1;
    }

    printf("MatMulCudaTiled -- n=%d, dtype=%s, tile=%dx%d\n",
           n, DTYPE_NAME, TILE, TILE);
    printf("Matrix memory per buffer: %.2f MB\n", bytes / (1024.0 * 1024.0));
    printf("Shared memory per block:  %lu bytes (2 x %d x %d x %lu)\n",
           (unsigned long)(2 * TILE * TILE * sizeof(real)),
           TILE, TILE, (unsigned long)sizeof(real));

    real *hA = (real*)malloc(bytes);
    real *hB = (real*)malloc(bytes);
    real *hC = (real*)malloc(bytes);
    if (!hA || !hB || !hC) { fprintf(stderr, "host malloc failed\n"); return 1; }

    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            hA[i * n + j] = (real)2.0;
            hB[i * n + j] = (real)3.0;
            hC[i * n + j] = (real)0.0;
        }

    real *dA, *dB, *dC;
    CUDA_CHECK(cudaMalloc(&dA, bytes));
    CUDA_CHECK(cudaMalloc(&dB, bytes));
    CUDA_CHECK(cudaMalloc(&dC, bytes));

    cudaEvent_t evStart, evH2D, evKernel, evD2H;
    cudaEventCreate(&evStart);
    cudaEventCreate(&evH2D);
    cudaEventCreate(&evKernel);
    cudaEventCreate(&evD2H);

    cudaEventRecord(evStart);

    CUDA_CHECK(cudaMemcpy(dA, hA, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, hB, bytes, cudaMemcpyHostToDevice));
    cudaEventRecord(evH2D);

    dim3 block(TILE, TILE);
    dim3 grid(n / TILE, n / TILE);
    matmul_tiled<<<grid, block>>>(dA, dB, dC, n);
    CUDA_CHECK(cudaGetLastError());
    cudaEventRecord(evKernel);

    CUDA_CHECK(cudaMemcpy(hC, dC, bytes, cudaMemcpyDeviceToHost));
    cudaEventRecord(evD2H);

    CUDA_CHECK(cudaEventSynchronize(evD2H));

    float ms_h2d = 0, ms_kernel = 0, ms_d2h = 0, ms_total = 0;
    cudaEventElapsedTime(&ms_h2d,    evStart,  evH2D);
    cudaEventElapsedTime(&ms_kernel, evH2D,    evKernel);
    cudaEventElapsedTime(&ms_d2h,    evKernel, evD2H);
    cudaEventElapsedTime(&ms_total,  evStart,  evD2H);

    real expected = (real)6.0 * (real)n;
    real got      = hC[0];
    real err      = (got > expected ? got - expected : expected - got);
    printf("C[0][0]   = %.6f (expected %.6f, abs err %.3e)\n",
           (double)got, (double)expected, (double)err);
    printf("C[n-1][n-1] = %.6f\n", (double)hC[(size_t)(n - 1) * n + (n - 1)]);

    printf("\n--- Timings (ms) ---\n");
    printf("H2D copy   : %10.3f ms\n", ms_h2d);
    printf("Kernel     : %10.3f ms\n", ms_kernel);
    printf("D2H copy   : %10.3f ms\n", ms_d2h);
    printf("Total GPU  : %10.3f ms  (%.3f s)\n", ms_total, ms_total / 1000.0);

    cudaEventDestroy(evStart);
    cudaEventDestroy(evH2D);
    cudaEventDestroy(evKernel);
    cudaEventDestroy(evD2H);
    cudaFree(dA); cudaFree(dB); cudaFree(dC);
    free(hA); free(hB); free(hC);
    return 0;
}
