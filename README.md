# mcc
Micro C Compiler

    gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
    ./mcc examples/hello.c hello && ./hello
