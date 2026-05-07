// Step 1: Naive CUDA matrix multiplication.
// Direct mapping of the triple loop in MatMul.c:
//   for i: for k: for j: c[i][j] += a[i][k] * b[k][j];
// One CUDA thread computes one element of C.
//
// Compile:
//   FP64:  nvcc -arch=sm_75 -O3                MatMulCuda.cu -o MatMulCuda_fp64
//   FP32:  nvcc -arch=sm_75 -O3 -DUSE_FLOAT    MatMulCuda.cu -o MatMulCuda_fp32

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define N 10000        // matrix size (n x n), same as readme n=10000 experiments

#ifndef BLOCK
#define BLOCK 16       // threads per block side; total threads/block = BLOCK*BLOCK
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

int main(void) {
    const int n = N;
    const size_t bytes = (size_t)n * n * sizeof(real);

    printf("MatMulCuda (naive) -- n=%d, dtype=%s, block=%dx%d\n",
           n, DTYPE_NAME, BLOCK, BLOCK);
    printf("Matrix memory per buffer: %.2f MB\n", bytes / (1024.0 * 1024.0));

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

    dim3 block(BLOCK, BLOCK);
    dim3 grid((n + BLOCK - 1) / BLOCK, (n + BLOCK - 1) / BLOCK);
    matmul_naive<<<grid, block>>>(dA, dB, dC, n);
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

    // Correctness check: C[i][j] = n * 2.0 * 3.0 = 6*n
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
