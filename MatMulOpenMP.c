#define n 5000

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <omp.h>

int main(int argc,char **argv) {
    int i, j, k;
    double t0= omp_get_wtime();
    // computation
    double t1 = omp_get_wtime();
    printf("MatMul time: %f seconds\n", t1 - t0);
    
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
    
    #pragma omp parallel for  schedule(static)
    // each thread gets different rows of c
    // no two threads update the same c[i][j] element, so no need for synchronization
    // i, j, k are private by default in OpenMP
    // No reduction atomic, or critical sections are needed because each thread works on a distinct portion of the output matrix c
    for (i=0; i<n; ++i)
        for (k=0; k<n; k++)
            for (j=0; j<n; ++j)
            c[i][j] += a[i][k]*b[k][j];
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
    time_taken = ((double)t) / CLOCKS_PER_SEC;
    printf("Second bottleneck: %f seconds \n ", time_taken);


    fclose(f);

    free(a);
    free(b);
    free(c);
    return 0;
}