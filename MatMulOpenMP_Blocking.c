    #define n 10000
    #define block_size 32

    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>
    #include <time.h>
    #include <omp.h>

    int main(int argc,char **argv) {
        int i, j, k;

        
        printf("starting program \n");
        double ( *a )[n] = malloc(sizeof(double[n][n]));
        double ( *b )[n] = malloc(sizeof(double[n][n]));
        double ( *c )[n] = malloc(sizeof(double[n][n]));

        #pragma omp parallel for collapse(2) schedule(static) // every iteration has the same amount of work, so static scheduling is appropriate
        // collapse is specially useful for matrix operations and static scheduling is best for regular loops
        for (i=0; i<n; i++)
            for (j=0; j<n; j++) {
                a[i][j] = 2.0;
                b[i][j] = 3.0;
                c[i][j] = 0.0;
            }
        double t0= omp_get_wtime();
        
        #pragma omp parallel for collapse(2) schedule(static)
        for (int ii = 0; ii < n; ii += block_size) {
            for (int jj = 0; jj < n; jj += block_size) {
                for (int kk = 0; kk < n; kk += block_size) {
                    for (int i = ii; i < ii + block_size && i < n; i++) {
                        for (int k = kk; k < kk + block_size && k < n; k++) {
                            double aik = a[i][k];
                            for (int j = jj; j < jj + block_size && j < n; j++) {
                                c[i][j] += aik * b[k][j];
                            }
                        }
                    }
                }
            }
        }

        double t1 = omp_get_wtime();
        printf("First bottleneck: %f seconds \n ", t1 - t0);
        



        FILE *f = fopen("mat-res.txt", "w");
        if (!f) {
            perror("fopen");
            return 1;
        }
        double t0= omp_get_wtime();
        fprintf(f, "%d\n\n", n);  
        for (int i = 0; i < 1000; i++) {
            for (int j = 0; j < 1000; j++) {
                fprintf(f, "%.0f ", c[i][j]);
            }
            fprintf(f, "\n");
        }

        double t1 = omp_get_wtime();
        printf("Second bottleneck: %f seconds \n ", t1 - t0);

        // test
        fclose(f);

        free(a);
        free(b);
        free(c);
        return 0;
    }