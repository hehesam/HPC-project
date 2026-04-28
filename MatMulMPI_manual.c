#define n 5000

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#define TAG_A 100
#define TAG_B 200
#define TAG_C 300

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int base = n / size;
    int rem  = n % size;
    int local_rows = base + (rank < rem ? 1 : 0);

    double (*A)[n] = NULL;
    double (*B)[n] = malloc(sizeof(double[n][n]));
    double (*C)[n] = NULL;

    double (*local_A)[n] = malloc(local_rows * sizeof(*local_A));
    double (*local_C)[n] = malloc(local_rows * sizeof(*local_C));

    if (!B || !local_A || !local_C) {
        fprintf(stderr, "Rank %d: malloc failed for local buffers\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    if (rank == 0) {
        A = malloc(sizeof(double[n][n]));
        C = malloc(sizeof(double[n][n]));
        if (!A || !C) {
            fprintf(stderr, "Rank 0: malloc failed for global buffers\n");
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                A[i][j] = 2.0;
                B[i][j] = 3.0;
                C[i][j] = 0.0;
            }
        }
    }

    for (int i = 0; i < local_rows; i++) {
        for (int j = 0; j < n; j++) {
            local_C[i][j] = 0.0;
        }
    }

    /* -----------------------------
       MANUAL DISTRIBUTION PHASE
       ----------------------------- */
    if (rank == 0) {
        int row_offset = 0;

        /* rank 0 keeps its own rows locally */
        int rows0 = base + (0 < rem ? 1 : 0);
        for (int i = 0; i < rows0; i++) {
            for (int j = 0; j < n; j++) {
                local_A[i][j] = A[row_offset + i][j];
            }
        }
        row_offset += rows0;

        /* send A blocks and full B to workers */
        for (int dest = 1; dest < size; dest++) {
            int rows_dest = base + (dest < rem ? 1 : 0);

            MPI_Send(&A[row_offset][0], rows_dest * n, MPI_DOUBLE,
                     dest, TAG_A, MPI_COMM_WORLD);

            MPI_Send(&B[0][0], n * n, MPI_DOUBLE,
                     dest, TAG_B, MPI_COMM_WORLD);

            row_offset += rows_dest;
        }
    } else {
        MPI_Recv(&local_A[0][0], local_rows * n, MPI_DOUBLE,
                 0, TAG_A, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

        MPI_Recv(&B[0][0], n * n, MPI_DOUBLE,
                 0, TAG_B, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();

    /* -----------------------------
       LOCAL COMPUTATION
       ----------------------------- */
    for (int i = 0; i < local_rows; i++) {
        for (int k = 0; k < n; k++) {
            double aik = local_A[i][k];
            for (int j = 0; j < n; j++) {
                local_C[i][j] += aik * B[k][j];
            }
        }
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double t1 = MPI_Wtime();

    /* -----------------------------
       MANUAL COLLECTION PHASE
       ----------------------------- */
    if (rank == 0) {
        int row_offset = 0;

        /* copy rank 0 local C into global C */
        int rows0 = base + (0 < rem ? 1 : 0);
        for (int i = 0; i < rows0; i++) {
            for (int j = 0; j < n; j++) {
                C[row_offset + i][j] = local_C[i][j];
            }
        }
        row_offset += rows0;

        /* receive worker results */
        for (int src = 1; src < size; src++) {
            int rows_src = base + (src < rem ? 1 : 0);

            MPI_Recv(&C[row_offset][0], rows_src * n, MPI_DOUBLE,
                     src, TAG_C, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            row_offset += rows_src;
        }

        printf("MPI manual point-to-point MatMul time: %f seconds\n", t1 - t0);

        FILE *f = fopen("mat-res.txt", "w");
        if (f) {
            fprintf(f, "%d\n\n", n);
            for (int i = 0; i < 1000; i++) {
                for (int j = 0; j < 1000; j++) {
                    fprintf(f, "%.0f ", C[i][j]);
                }
                fprintf(f, "\n");
            }
            fclose(f);
        }
    } else {
        MPI_Send(&local_C[0][0], local_rows * n, MPI_DOUBLE,
                 0, TAG_C, MPI_COMM_WORLD);
    }

    free(local_A);
    free(local_C);
    free(B);

    if (rank == 0) {
        free(A);
        free(C);
    }

    MPI_Finalize();
    return 0;
}