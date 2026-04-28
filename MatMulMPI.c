#define n 5000

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int base = n / size;
    int rem  = n % size;
    int local_rows = base + (rank < rem ? 1 : 0);

    int *counts = malloc(size * sizeof(int));
    int *displs = malloc(size * sizeof(int));

    int offset = 0;
    for (int r = 0; r < size; r++) {
        int rows_r = base + (r < rem ? 1 : 0);
        counts[r] = rows_r * n;
        displs[r] = offset;
        offset += counts[r];
    }

    double (*A)[n] = NULL;
    double (*C)[n] = NULL;
    double (*B)[n] = malloc(sizeof(double[n][n]));
    double (*local_A)[n] = malloc(local_rows * sizeof(*local_A));
    double (*local_C)[n] = malloc(local_rows * sizeof(*local_C));

    if (rank == 0) {
        A = malloc(sizeof(double[n][n]));
        C = malloc(sizeof(double[n][n]));

        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++) {
                A[i][j] = 2.0;
                B[i][j] = 3.0;
                C[i][j] = 0.0;
            }
    }

    for (int i = 0; i < local_rows; i++)
        for (int j = 0; j < n; j++)
            local_C[i][j] = 0.0;

    MPI_Scatterv(rank == 0 ? &A[0][0] : NULL, counts, displs, MPI_DOUBLE,
                 &local_A[0][0], local_rows * n, MPI_DOUBLE,
                 0, MPI_COMM_WORLD);

    MPI_Bcast(&B[0][0], n * n, MPI_DOUBLE, 0, MPI_COMM_WORLD);

    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();

    for (int i = 0; i < local_rows; i++)
        for (int k = 0; k < n; k++) {
            double aik = local_A[i][k];
            for (int j = 0; j < n; j++)
                local_C[i][j] += aik * B[k][j];
        }

    MPI_Barrier(MPI_COMM_WORLD);
    double t1 = MPI_Wtime();

    MPI_Gatherv(&local_C[0][0], local_rows * n, MPI_DOUBLE,
                rank == 0 ? &C[0][0] : NULL, counts, displs, MPI_DOUBLE,
                0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("MPI MatMul time: %f seconds\n", t1 - t0);

        FILE *f = fopen("mat-res.txt", "w");
        if (f) {
            fprintf(f, "%d\n\n", n);
            for (int i = 0; i < 1000; i++) {
                for (int j = 0; j < 1000; j++)
                    fprintf(f, "%.0f ", C[i][j]);
                fprintf(f, "\n");
            }
            fclose(f);
        }
    }

    free(local_A);
    free(local_C);
    free(B);
    free(counts);
    free(displs);
    if (rank == 0) {
        free(A);
        free(C);
    }

    MPI_Finalize();
    return 0;
}