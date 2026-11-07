# mcc

Micro C compiler.

    gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
    ./mcc examples/hello.c hello && ./hello

Currently compiles a file of functions (`int` or `void`, up to 12 `int` parameters, prototypes, recursion), one of them `int main()`. A function has to be declared before it's called, as in C. Inside a function:

    int x = 5;  int y;  x = x + 1;   // int variables only
    x++;  x--;  ++x;  --x;  x += <expression>;  (also -= *= /= %=)
    puts("...");  putn(<expression>);  return <expression>;
    if (<expression>) <statement>  else <statement>
    while (<expression>) <statement>
    for (<init>; <expression>; <step>) <statement>   // any part can be empty
    { <statements> }               // a block, variables inside stay inside

`//` and `/* */` comments work anywhere.

Expressions: numbers (decimal, hex like `0x1F`, characters like `'a'` and `'\n'`), variables, `+ - * / %`, `== != < > <= >=` and `x++ x-- ++x --x`, `&& || !` (all give 1 or 0, and `&&` / `||` skip the right side when they can), brackets, unary minus.

    sh tests/run.sh    # builds mcc with gcc, runs the tests