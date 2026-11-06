# mcc

Micro C compiler.

    gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
    ./mcc examples/hello.c hello && ./hello

Currently compiles `int main() { ... }` containing:

    int x = 5;  int y;  x = x + 1;   // int variables only
    x++;  x--;  ++x;  --x;  x += <expression>;  (also -= *= /= %=)
    puts("...");  putn(<expression>);  return <expression>;
    if (<expression>) <statement>  else <statement>
    while (<expression>) <statement>
    { <statements> }               // a block, variables inside stay inside

`//` and `/* */` comments work anywhere.

Expressions: numbers, variables, `+ - * / %`, `== != < > <= >=` and `x++ x-- ++x --x`, `&& || !` (all give 1 or 0, and `&&` / `||` skip the right side when they can), brackets, unary minus.

    sh tests/run.sh    # builds mcc with gcc, runs the tests