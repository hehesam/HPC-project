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
