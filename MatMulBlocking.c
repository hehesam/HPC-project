#define n 5000
#define block_size 32

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
int main(int argc,char **argv) {
  int i, j, k;
  int ii, jj, kk;
  clock_t t;
  
  printf("starting program \n");
  double ( *a )[n] = malloc(sizeof(double[n][n]));
  double ( *b )[n] = malloc(sizeof(double[n][n]));
  double ( *c )[n] = malloc(sizeof(double[n][n]));

  for (i=0; i<n; i++)
     for (j=0; j<n; j++) {
        a[i][j] = 2.0;
        b[i][j] = 3.0;
        c[i][j] = 0.0;
     }
  t = clock();

  for (ii=0; ii<n; ii+=block_size)
     for (kk=0; kk<n; kk+=block_size)
        for (jj=0; jj<n; jj+=block_size)

           for (i=ii; i<ii+block_size && i<n; ++i)
              for (k=kk; k<kk+block_size && k<n; k++){
                double aik = a[i][k]; // we load a value once and reuse it for the inner j loop
                for (j=jj; j<jj+block_size && j<n; ++j)
                    c[i][j] += aik * b[k][j];
                }

  t =clock() - t;
  double time_taken = ((double)t) / CLOCKS_PER_SEC;
  printf("First bottleneck: %f seconds \n ", time_taken);



  FILE *f = fopen("mat-res.txt", "w");
  if (!f) {
     perror("fopen");
      return 1;
  }
  t = clock();
  fprintf(f, "%d\n\n", n);  
  for (int i = 0; i < 1000; i++) {
     for (int j = 0; j < 1000; j++) {
        fprintf(f, "%.0f ", c[i][j]);
     }
     fprintf(f, "\n");
  }

  t = clock() - t;
  time_taken = ((double)t) / CLOCKS_PER_SEC;
  printf("Second bottleneck: %f seconds \n ", time_taken);


  fclose(f);

  free(a);
  free(b);
  free(c);
  return 0;
}