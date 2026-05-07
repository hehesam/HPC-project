// Step 5: cuBLAS reference (practical upper bound).
// Calls cublasSgemm (FP32) or cublasDgemm (FP64) on the same input matrices
// as the hand-written kernels so we can measure how much head-room we leave
// by stopping at single-tile shared-memory blocking.
//
// Compile (note the -lcublas flag):
//   FP64: nvcc -arch=sm_75 -O3            MatMulCublas.cu -o MatMulCublas_fp64 -lcublas
//   FP32: nvcc -arch=sm_75 -O3 -DUSE_FLOAT MatMulCublas.cu -o MatMulCublas_fp32 -lcublas
//
// cuBLAS is column-major. We store A, B, C row-major (same as the other
// experiments) and use the classic trick: compute C^T = B^T * A^T in
// column-major, which gives the correct row-major layout in C without
// any transpose copies. For square matrices and our uniform 2.0 / 3.0
// fill the result is identical.

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <cublas_v2.h>

#define N 10000

#ifdef USE_FLOAT
typedef float real;
#define DTYPE_NAME "float (FP32)"
#define CUBLAS_GEMM cublasSgemm
#else
typedef double real;
#define DTYPE_NAME "double (FP64)"
#define CUBLAS_GEMM cublasDgemm
#endif

#define CUDA_CHECK(call) do {                                          \
    cudaError_t err = (call);                                          \
    if (err != cudaSuccess) {                                          \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                      \
                __FILE__, __LINE__, cudaGetErrorString(err));          \
        exit(1);                                                       \
    }                                                                  \
} while (0)

#define CUBLAS_CHECK(call) do {                                        \
    cublasStatus_t s = (call);                                         \
    if (s != CUBLAS_STATUS_SUCCESS) {                                  \
        fprintf(stderr, "cuBLAS error %s:%d: %d\n", __FILE__, __LINE__, (int)s); \
        exit(1);                                                       \
    }                                                                  \
} while (0)

int main(void) {
    const int n = N;
    const size_t bytes = (size_t)n * n * sizeof(real);

    printf("MatMulCublas -- n=%d, dtype=%s\n", n, DTYPE_NAME);
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

    cublasHandle_t handle;
    CUBLAS_CHECK(cublasCreate(&handle));

    cudaEvent_t evStart, evH2D, evKernel, evD2H;
    cudaEventCreate(&evStart);
    cudaEventCreate(&evH2D);
    cudaEventCreate(&evKernel);
    cudaEventCreate(&evD2H);

    cudaEventRecord(evStart);

    CUDA_CHECK(cudaMemcpy(dA, hA, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, hB, bytes, cudaMemcpyHostToDevice));
    cudaEventRecord(evH2D);

    // Warm-up call (untimed). cuBLAS lazily JIT-compiles its kernels on the
    // first invocation, so without a warm-up we would charge that one-off
    // cost to our timing window. Run gemm once and synchronise before the
    // timed call.
    {
        const real alpha = (real)1.0;
        const real beta  = (real)0.0;
        // Compute C^T = B^T * A^T in column-major (= C = A*B in row-major).
        // m = n_cols of C^T = n, n = n_rows of C^T = n, k = n_cols of A^T = n.
        CUBLAS_CHECK(CUBLAS_GEMM(handle,
                                 CUBLAS_OP_N, CUBLAS_OP_N,
                                 n, n, n,
                                 &alpha,
                                 dB, n,
                                 dA, n,
                                 &beta,
                                 dC, n));
        CUDA_CHECK(cudaDeviceSynchronize());
    }

    // Re-record so the H2D->Kernel window only contains the timed gemm.
    cudaEventRecord(evH2D);

    {
        const real alpha = (real)1.0;
        const real beta  = (real)0.0;
        CUBLAS_CHECK(CUBLAS_GEMM(handle,
                                 CUBLAS_OP_N, CUBLAS_OP_N,
                                 n, n, n,
                                 &alpha,
                                 dB, n,
                                 dA, n,
                                 &beta,
                                 dC, n));
    }
    cudaEventRecord(evKernel);

    CUDA_CHECK(cudaMemcpy(hC, dC, bytes, cudaMemcpyDeviceToHost));
    cudaEventRecord(evD2H);

    CUDA_CHECK(cudaEventSynchronize(evD2H));

    float ms_h2d = 0, ms_kernel = 0, ms_d2h = 0;
    // Note: ms_h2d here is the time *after* the warm-up gemm because we
    // re-recorded evH2D; the original H2D copy time is included in
    // (evStart -> warmup_done). We measure it separately below.
    cudaEventElapsedTime(&ms_kernel, evH2D,    evKernel);
    cudaEventElapsedTime(&ms_d2h,    evKernel, evD2H);

    // Re-measure pure H2D by replaying just the copy on a fresh event pair
    // (matrices are unchanged on host, so this gives a clean number).
    cudaEvent_t cpStart, cpEnd;
    cudaEventCreate(&cpStart);
    cudaEventCreate(&cpEnd);
    cudaEventRecord(cpStart);
    CUDA_CHECK(cudaMemcpy(dA, hA, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, hB, bytes, cudaMemcpyHostToDevice));
    cudaEventRecord(cpEnd);
    CUDA_CHECK(cudaEventSynchronize(cpEnd));
    cudaEventElapsedTime(&ms_h2d, cpStart, cpEnd);
    cudaEventDestroy(cpStart);
    cudaEventDestroy(cpEnd);

    float ms_total = ms_h2d + ms_kernel + ms_d2h;

    real expected = (real)6.0 * (real)n;
    real got      = hC[0];
    real err      = (got > expected ? got - expected : expected - got);
    printf("C[0][0]   = %.6f (expected %.6f, abs err %.3e)\n",
           (double)got, (double)expected, (double)err);
    printf("C[n-1][n-1] = %.6f\n", (double)hC[(size_t)(n - 1) * n + (n - 1)]);

    printf("\n--- Timings (ms, after warm-up) ---\n");
    printf("H2D copy   : %10.3f ms\n", ms_h2d);
    printf("Kernel     : %10.3f ms  (cuBLAS %s)\n", ms_kernel,
#ifdef USE_FLOAT
           "Sgemm"
#else
           "Dgemm"
#endif
    );
    printf("D2H copy   : %10.3f ms\n", ms_d2h);
    printf("Total GPU  : %10.3f ms  (%.3f s)\n", ms_total, ms_total / 1000.0);

    cudaEventDestroy(evStart);
    cudaEventDestroy(evH2D);
    cudaEventDestroy(evKernel);
    cudaEventDestroy(evD2H);
    cublasDestroy(handle);
    cudaFree(dA); cudaFree(dB); cudaFree(dC);
    free(hA); free(hB); free(hC);
    return 0;
}
