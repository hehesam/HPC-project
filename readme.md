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
4. maximum optimization: gcc -O3 MatMul.c -o MatMul_O3
./MatMul_O3