# mcc

Micro C compiler.

    gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
    ./mcc examples/hello.c hello && ./hello

Currently compiles `int main() { ... }` containing:

    int x = 5;  int y;  x = x + 1;   // int variables only
    puts("...");  putn(<expression>);  return <expression>;
    if (<expression>) <statement>  else <statement>
    { <statements> }               // a block, variables inside stay inside

Expressions: numbers, variables, `+ - * / %`, `== != < > <= >=` (give 1 or 0), brackets, unary minus.

    sh tests/run.sh    # builds mcc with gcc, runs the tests