#define n 5000

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
int main(int argc,char **argv) {
  int i, j, k;
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
  for (i=0; i<n; ++i)
     for (k=0; k<n; k++)
        for (j=0; j<n; ++j)
           c[i][j] += a[i][k]*b[k][j];
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