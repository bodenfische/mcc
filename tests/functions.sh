# functions: parameters, calls, return, recursion, prototypes
. "$(dirname "$0")/lib.sh"

# prog NAME EXPECTED-OUTPUT   (the program text comes from stdin)
prog() {
    cat > "$tmp/p.c"
    check "$1" "$2" "$tmp/p.c"
}

prog no-params 7 <<'EOC'
int seven() { return 7; }
int main() { putn(seven()); return 0; }
EOC

prog one-param 10 <<'EOC'
int twice(int x) { return x * 2; }
int main() { putn(twice(5)); return 0; }
EOC

prog two-params-order 7 <<'EOC'
int sub(int a, int b) { return a - b; }
int main() { putn(sub(10, 3)); return 0; }
EOC

prog three-params-order 321 <<'EOC'
int digits(int a, int b, int c) { return a * 100 + b * 10 + c; }
int main() { putn(digits(3, 2, 1)); return 0; }
EOC

prog six-params 123456 <<'EOC'
int f(int a, int b, int c, int d, int e, int g) { return a * 100000 + b * 10000 + c * 1000 + d * 100 + e * 10 + g; }
int main() { putn(f(1, 2, 3, 4, 5, 6)); return 0; }
EOC

prog twelve-params 78 <<'EOC'
int f(int a, int b, int c, int d, int e, int g, int h, int i, int j, int k, int l, int m) {
    return a + b + c + d + e + g + h + i + j + k + l + m;
}
int main() { putn(f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)); return 0; }
EOC

prog expression-args 25 <<'EOC'
int add(int a, int b) { return a + b; }
int main() { int x = 4; putn(add(x * 2, add(x, 13))); return 0; }
EOC

prog result-in-expr 17 <<'EOC'
int sq(int x) { return x * x; }
int main() { putn(sq(3) + sq(2) * 4 - 8); return 0; }
EOC

prog call-in-condition "$(printf '1\n0')" <<'EOC'
int positive(int x) { return x > 0; }
int main() { if (positive(5)) putn(1); else putn(0); if (positive(-5)) putn(1); else putn(0); return 0; }
EOC

prog call-statement "$(printf '1\n2\n3')" <<'EOC'
int show(int x) { putn(x); return x; }
int main() { show(1); show(2); show(3); return 0; }
EOC

# void functions
prog void-function "$(printf 'hello\n42')" <<'EOC'
void greet() { puts("hello"); }
int main() { greet(); putn(42); return 0; }
EOC

prog void-param "$(printf '5\n6\n7')" <<'EOC'
void show(int x) { putn(x); }
int main() { show(5); show(6); show(7); return 0; }
EOC

prog void-early-return "$(printf '1\n3')" <<'EOC'
void maybe(int x) { if (x == 2) return; putn(x); }
int main() { maybe(1); maybe(2); maybe(3); return 0; }
EOC

prog void-keyword-params 9 <<'EOC'
int nine(void) { return 9; }
int main(void) { putn(nine()); return 0; }
EOC

# return
prog early-return "$(printf '1\n2')" <<'EOC'
int check(int x) { if (x > 0) return 1; return 2; }
int main() { putn(check(5)); putn(check(-5)); return 0; }
EOC

prog return-in-loop 5 <<'EOC'
int find(int n) { for (int i = 0; ; i++) { if (i * i > n) return i - 1; } }
int main() { putn(find(30)); return 0; }
EOC

prog fall-off-end-main 3 <<'EOC'
int main() { putn(3); }
EOC

# locals and parameters
prog param-is-a-copy "$(printf '5\n99\n5')" <<'EOC'
int change(int x) { x = 99; return x; }
int main() { int a = 5; putn(a); putn(change(a)); putn(a); return 0; }
EOC

prog params-and-locals 30 <<'EOC'
int f(int a, int b) { int c = a + b; int d = c * 2; return d; }
int main() { putn(f(5, 10)); return 0; }
EOC

prog param-modified 12 <<'EOC'
int f(int x) { x += 5; x *= 2; return x; }
int main() { putn(f(1)); return 0; }
EOC

prog locals-dont-clash 3 <<'EOC'
int f(int x) { int y = x + 1; return y; }
int main() { int y = 1; int z = f(y); putn(z + y); return 0; }
EOC

prog same-names "$(printf '1\n2')" <<'EOC'
int f(int x) { return x + 1; }
int main() { int x = 1; putn(x); putn(f(x)); return 0; }
EOC

prog block-scope-inside "$(printf '5\n8')" <<'EOC'
int f(int a) { { int b = a + 3; putn(a); a = b; } return a; }
int main() { putn(f(5)); return 0; }
EOC

prog loop-in-function 55 <<'EOC'
int sum(int n) { int s = 0; for (int i = 1; i <= n; i++) s += i; return s; }
int main() { putn(sum(10)); return 0; }
EOC

# several functions calling each other
prog chain 12 <<'EOC'
int a(int x) { return x + 1; }
int b(int x) { return a(x) * 2; }
int c(int x) { return b(x) + a(x); }
int main() { putn(c(3)); return 0; }
EOC

prog calls-inside-args 12 <<'EOC'
int add(int a, int b) { return a + b; }
int mul(int a, int b) { return a * b; }
int main() { putn(add(mul(2, 3), mul(add(1, 1), 3))); return 0; }
EOC

prog min-max "$(printf '3\n9')" <<'EOC'
int min(int a, int b) { if (a < b) return a; return b; }
int max(int a, int b) { if (a > b) return a; return b; }
int main() { putn(min(9, 3)); putn(max(9, 3)); return 0; }
EOC

# recursion
prog factorial 3628800 <<'EOC'
int fact(int n) { if (n <= 1) return 1; return n * fact(n - 1); }
int main() { putn(fact(10)); return 0; }
EOC

prog fibonacci 55 <<'EOC'
int fib(int n) { if (n < 2) return n; return fib(n - 1) + fib(n - 2); }
int main() { putn(fib(10)); return 0; }
EOC

prog fibonacci-25 75025 <<'EOC'
int fib(int n) { if (n < 2) return n; return fib(n - 1) + fib(n - 2); }
int main() { putn(fib(25)); return 0; }
EOC

prog gcd 6 <<'EOC'
int gcd(int a, int b) { if (b == 0) return a; return gcd(b, a % b); }
int main() { putn(gcd(48, 18)); return 0; }
EOC

prog power 1024 <<'EOC'
int power(int b, int e) { if (e == 0) return 1; return b * power(b, e - 1); }
int main() { putn(power(2, 10)); return 0; }
EOC

prog deep-recursion 50005000 <<'EOC'
int sum(int n) { if (n == 0) return 0; return n + sum(n - 1); }
int main() { putn(sum(10000)); return 0; }
EOC

prog ackermann "$(printf '9\n61')" <<'EOC'
int ack(int m, int n) {
    if (m == 0) return n + 1;
    if (n == 0) return ack(m - 1, 1);
    return ack(m - 1, ack(m, n - 1));
}
int main() { putn(ack(2, 3)); putn(ack(3, 3)); return 0; }
EOC

prog digits-sum 15 <<'EOC'
int digits(int n) { if (n == 0) return 0; return n % 10 + digits(n / 10); }
int main() { putn(digits(12345)); return 0; }
EOC

# prototypes: calling a function defined further down
prog prototype 6 <<'EOC'
int later(int x);
int main() { putn(later(3)); return 0; }
int later(int x) { return x * 2; }
EOC

prog prototype-no-names 6 <<'EOC'
int later(int);
int main() { putn(later(3)); return 0; }
int later(int x) { return x * 2; }
EOC

prog prototype-void 4 <<'EOC'
void show(int);
int main() { show(4); return 0; }
void show(int x) { putn(x); }
EOC

prog mutual-recursion "$(printf '1\n0\n1\n0')" <<'EOC'
int is_odd(int n);
int is_even(int n) { if (n == 0) return 1; return is_odd(n - 1); }
int is_odd(int n) { if (n == 0) return 0; return is_even(n - 1); }
int main() { putn(is_even(10)); putn(is_even(7)); putn(is_odd(7)); putn(is_odd(10)); return 0; }
EOC

prog prototype-twice 5 <<'EOC'
int f(int x);
int f(int y);
int main() { putn(f(5)); return 0; }
int f(int z) { return z; }
EOC

prog empty-prototype 2 <<'EOC'
int f();
int main() { putn(f()); return 0; }
int f() { return 2; }
EOC

# comments, strings and everything else still work inside functions
prog comments-and-strings "$(printf 'hi\n3')" <<'EOC'
// a helper
int three() { /* three */ return 3; }
int main() { puts("hi"); putn(three()); return 0; }
EOC

# main's return value is the program's exit code
exits() {
    cat > "$tmp/p.c"
    ./mcc "$tmp/p.c" "$tmp/x" && run "$tmp/x" > /dev/null
    got=$?
    if [ "$got" = "$2" ]; then echo "ok   $1"; pass=$((pass + 1)); else echo "FAIL $1 (exit $got, wanted $2)"; fail=$((fail + 1)); fi
}

exits exit-seven 7 <<'EOC'
int main() { return 7; }
EOC
exits exit-zero 0 <<'EOC'
int main() { return 0; }
EOC
exits exit-falls-off 0 <<'EOC'
int main() { putn(1); }
EOC
exits exit-from-call 6 <<'EOC'
int f(int x) { return x * 2; }
int main() { return f(3); }
EOC
exits exit-from-early-return 3 <<'EOC'
int main() { if (1) return 3; return 4; }
EOC

# things mcc must refuse
refuse() {
    cat > "$tmp/p.c"
    if ./mcc "$tmp/p.c" "$tmp/x" 2>/dev/null; then echo "FAIL $1"; fail=$((fail + 1)); else echo "ok   $1"; pass=$((pass + 1)); fi
}

refuse call-before-declaration <<'EOC'
int main() { putn(f()); return 0; }
int f() { return 1; }
EOC
refuse too-few-arguments <<'EOC'
int f(int a, int b) { return a + b; }
int main() { putn(f(1)); return 0; }
EOC
refuse too-many-arguments <<'EOC'
int f(int a) { return a; }
int main() { putn(f(1, 2)); return 0; }
EOC
refuse arguments-to-none <<'EOC'
int f() { return 1; }
int main() { putn(f(1)); return 0; }
EOC
refuse void-as-value <<'EOC'
void f() { }
int main() { putn(f()); return 0; }
EOC
refuse void-returns-value <<'EOC'
void f() { return 1; }
int main() { f(); return 0; }
EOC
refuse int-returns-nothing <<'EOC'
int f() { return; }
int main() { putn(f()); return 0; }
EOC
refuse defined-twice <<'EOC'
int f() { return 1; }
int f() { return 2; }
int main() { return 0; }
EOC
refuse prototype-wrong-params <<'EOC'
int f(int a);
int f(int a, int b) { return a; }
int main() { return 0; }
EOC
refuse prototype-wrong-type <<'EOC'
int f();
void f() { }
int main() { return 0; }
EOC
refuse never-defined <<'EOC'
int f();
int main() { return f(); }
EOC
refuse no-main <<'EOC'
int f() { return 1; }
EOC
refuse empty-file <<'EOC'
EOC
refuse duplicate-parameter <<'EOC'
int f(int a, int a) { return a; }
int main() { return 0; }
EOC
refuse parameter-redeclared <<'EOC'
int f(int a) { int a; return a; }
int main() { return 0; }
EOC
refuse unnamed-parameter <<'EOC'
int f(int) { return 1; }
int main() { return 0; }
EOC
refuse too-many-parameters <<'EOC'
int f(int a, int b, int c, int d, int e, int g, int h, int i, int j, int k, int l, int m, int n) { return 1; }
int main() { return 0; }
EOC
refuse stray-text <<'EOC'
5;
int main() { return 0; }
EOC
refuse missing-brace <<'EOC'
int main() return 0;
EOC
refuse unclosed-call <<'EOC'
int f(int a) { return a; }
int main() { putn(f(1); return 0; }
EOC
refuse variable-as-function <<'EOC'
int main() { int x = 1; putn(x(2)); return 0; }
EOC
refuse function-as-variable <<'EOC'
int f() { return 1; }
int main() { putn(f); return 0; }
EOC

# and the messages say what's wrong, and where
cat > "$tmp/m1.c" <<'EOC'
int main() {
    putn(f(1));
    return 0;
}
EOC
says undeclared-function-message "$tmp/m1.c" "mcc: line 2: undeclared function 'f'"

cat > "$tmp/m2.c" <<'EOC'
int add(int a, int b) { return a + b; }
int main() {
    return add(1);
}
EOC
says arg-count-message "$tmp/m2.c" "mcc: line 3: wrong number of arguments to 'add'"

cat > "$tmp/m3.c" <<'EOC'
int f() { return 1; }
EOC
says no-main-message "$tmp/m3.c" "mcc: no main function"

cat > "$tmp/m4.c" <<'EOC'
int f();
int main() { return f(); }
EOC
says never-defined-message "$tmp/m4.c" "mcc: declared but never defined 'f'"

finish