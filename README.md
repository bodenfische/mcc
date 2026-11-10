# mcc

Micro C compiler.

    gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
    ./mcc examples/hello.c hello && ./hello

Currently compiles a file of functions (`int`, `long` or `void`, up to 12 parameters, pointer parameters and return types, prototypes, recursion), one of them `int main()`. A function has to be declared before it's called, as in C. Global `int` and `long` variables work too (zero unless given a starting value, which has to be a single number), and `static` is accepted. Inside a function:

    int x = 5;  int y;  x = x + 1;   // int (32 bit), long (64 bit), or pointers to them: int *p = &x;
    x++;  x--;  ++x;  --x;  x += <expression>;  (also -= *= /= %=)
    puts("...");  putn(<expression>);  return <expression>;
    if (<expression>) <statement>  else <statement>
    while (<expression>) <statement>
    for (<init>; <expression>; <step>) <statement>   // any part can be empty
    { <statements> }               // a block, variables inside stay inside

`//` and `/* */` comments work anywhere.

Expressions: numbers (decimal, hex like `0x1F`, characters like `'a'` and `'\n'`), variables, `+ - * / %` (an `int` mixed with a `long` is widened, as in C), `== != < > <= >=` and `x++ x-- ++x --x`, `&x` and `*p` (pointers to `int`, `long` or other pointers, with `p + 1` stepping a whole element and `p - q` counting them), `&& || !` (all give 1 or 0, and `&&` / `||` skip the right side when they can), brackets, unary minus.

    sh tests/run.sh    # builds mcc with gcc, runs the tests