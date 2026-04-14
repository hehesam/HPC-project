# First experiment compiler optimization
1. no optimization: gcc -O0 -o MatMul_O0.exe MatMul.c -lm MatMul_O0.exe
2. basic optimization: gcc -O1 -o MatMul_O1.exe MatMul.c -lm MatMul_O1.exe
3. more optimization: gcc -O2 -o MatMul_O2.exe MatMul.c -lm MatMul_O2.exe
4. maximum optimization: gcc -O3 -o MatMul_O3.exe MatMul.c -lm MatMul_O3.exe