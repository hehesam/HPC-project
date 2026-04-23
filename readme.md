## set up for compiler:
source /opt/intel/oneapi/setvars.sh

## for Intel Adviser:
advixe-gui

# First experiment compiler optimization
1. no optimization: gcc MatMul.c -o MatMul_O0
./MatMul_O0
*   first loop result: 211 second
2. basic optimization: gcc -O1 MatMul.c -o MatMul_O1
./MatMul_O1
*   first loop result: 67.4142
*   second loop result: 0.1283
3. more optimization: gcc -O2 MatMul.c -o MatMul_O2
./MatMul_O2
*   first loop result: 54.3686
*   0.128724
4. maximum optimization: gcc -O3 MatMul.c -o MatMul_O3
    ./MatMul_O3
*   First loop result: 37.534927
*   Second loop result: 0.128871
5. optimization 4

# Second experiemnt with ICC compiler
1. icc -O3 MatMul.c -o MatMul_icc_O4 ./MatMul_icc_O3
*   First bottleneck: 18.264099
*   Second bottleneck: 0.129084
2. Runnign for n = 10000:
*   First bottleneck: 365.593128
*   second
3. Runnign n=10000 with blocking:
*   First bottleneck: 149.125418
*   Second bottleneck: 0.132787

# Third experiment with ICX compiler:
1. icx Matmul.c -O3 -o Matmul:
*   First bottleneck: 50.1430
*   Second bottleneck: 

# OpenMP experiments
## OpenMP ICC XHost on 10000 samples
*   43.569727
*   0.132649
## OpenMP ICC XHost with Blocking
1. 24 threads
*   14.362156
*   0.130031
2. 32 threads
*   15.616791
*   0.135189
3. 8 threads:
*   23.192564
*   0.133868
4. 12 threads:
*   21.446184
*   0.132584
5. 16 threads:
*   17.905209
*   0.13265
## OpenMP ICC  XHost with blocking with different schedulees
1. dynamic
*   15.04
2. Guided
*   15.536664
3. Static:
*   1 chunck size: 14.45
*   4 chunck size: 14.402
*   16 chunck size: 14.4022041

google docs link
https://docs.google.com/document/d/1qt4il0NrqpDt9coAq8w0jO6MP3vAU-j10cAJX2-bWlo/edit?usp=sharing
