# long: 64 bit integers, and mixing them with int
. "$(dirname "$0")/lib.sh"

# values
body  small            5                    'long x = 5; putn(x);'
body  over-int         3000000000           'long x = 3000000000; putn(x);'
body  long-max         9223372036854775807  'long x = 9223372036854775807; putn(x);'
body  long-min         -9223372036854775808 'long x = -9223372036854775807 - 1; putn(x);'
body  long-min-direct  -9223372036854775808 'putn(-9223372036854775807 - 1);'
body  negative         -5000000000          'long x = -5000000000; putn(x);'
body  zero             0                    'long x = 0; putn(x);'

# literals: an int if it fits, otherwise a long
body  lit-int-max      2147483647           'putn(2147483647);'
body  lit-over-int     2147483648           'putn(2147483648);'
body  lit-neg-int-min  -2147483648          'putn(-2147483648);'
body  lit-hex-int-max  2147483647           'putn(0x7fffffff);'
body  lit-hex-over     2147483648           'putn(0x80000000);'
body  lit-hex-32-bits  4294967295           'putn(0xFFFFFFFF);'
body  lit-hex-33-bits  4294967296           'putn(0x100000000);'
body  lit-hex-max      9223372036854775807  'putn(0x7fffffffffffffff);'
body  lit-plus-int     4294967297           'int a = 1; putn(a + 4294967296);'

# converting between int and long
body  widen-negative   -5          'int a = -5; long b = a; putn(b);'
body  widen-int-max    2147483648  'int a = 2147483647; long b = a; b = b + 1; putn(b);'
body  narrow-wraps     1           'long a = 4294967297; int b = a; putn(b);'
body  narrow-sign      -2147483648 'long a = 2147483648; int b = a; putn(b);'
body  narrow-small     42          'long a = 42; int b = a; putn(b);'
body  assign-widens    -7          'long x; int y = -7; x = y; putn(x);'
body  assign-narrows   3           'int x; long y = 4294967299; x = y; putn(x);'
body  sign-not-zero    1           'int a = -1; long b = -1; putn(a == b);'
body  not-zero-extend  0           'int a = -1; long b = 4294967295; putn(a == b);'
body  int-less-than    1           'int a = -1; long b = 4294967295; putn(a < b);'

# arithmetic
body  add              6000000000  'long a = 3000000000; putn(a + a);'
body  sub              -2000000000 'long a = 3000000000; putn(a - 5000000000);'
body  mul              6000000000  'long a = 3000000000; putn(a * 2);'
body  div              428571428   'long a = 3000000000; putn(a / 7);'
body  mod              4           'long a = 3000000000; putn(a % 7);'
body  neg-div          -428571428  'long a = 3000000000; putn(-a / 7);'
body  neg-mod          -4          'long a = 3000000000; putn(-a % 7);'
body  negate           -5000000000 'long a = 5000000000; putn(-a);'
body  precedence       23000000000 'long a = 1000000000; putn(a + 2 * 11 * a);'
body  mixed-mul        12000000000 'long a = 4000000000; int b = 3; putn(a * b);'
body  mixed-mul-swap   12000000000 'long a = 4000000000; int b = 3; putn(b * a);'
body  mixed-sub        3999999997  'long a = 4000000000; int b = 3; putn(a - b);'
body  mixed-sub-swap   -3999999997 'long a = 4000000000; int b = 3; putn(b - a);'
body  mixed-div        1333333333  'long a = 4000000000; int b = 3; putn(a / b);'
body  mixed-div-swap   0           'long a = 4000000000; int b = 3; putn(b / a);'
body  mixed-mod        1           'long a = 4000000000; int b = 3; putn(a % b);'
body  negative-int     3999999997  'long a = 4000000000; int b = -3; putn(a + b);'

# comparisons give an int
body  gt               1           'long a = 5000000000; putn(a > 4000000000);'
body  lt               0           'long a = 5000000000; putn(a < 4000000000);'
body  eq               1           'long a = 5000000000; putn(a == 5000000000);'
body  ne               0           'long a = 5000000000; putn(a != 5000000000);'
body  high-half-only   1           'long a = 4294967296; long b = 0; putn(a != b);'
body  le-ge            "$(printf '1\n1\n0')" 'long a = 5000000000; putn(a <= 5000000000); putn(a >= 5000000000); putn(a < 5000000000);'
body  compare-int      1           'int x = 5; long y = 5; putn(x == y);'

# the 64 bit value is tested, not just its low half
body  not-high-half    0           'long a = 4294967296; putn(!a);'
body  not-zero-long    1           'long a = 0; putn(!a);'
body  if-high-half     1           'long a = 4294967296; if (a) putn(1); else putn(0);'
body  while-high-half  3           'long a = 12884901888; int n = 0; while (a) { a -= 4294967296; n++; } putn(n);'
body  for-high-half    "$(printf '0\n1\n2')" 'for (long i = 0; i < 3; i++) putn(i);'
body  and-high-half    1           'long a = 4294967296; putn(a && 1);'
body  or-high-half     1           'long a = 4294967296; putn(0 || a);'
body  and-or-mixed     "$(printf '0\n1\n1')" 'long a = 4294967296; int b = 0; putn(a && b); putn(a || b); putn(b || a);'

# ++ -- and compound assignment
body  inc-carries      4294967296  'long x = 4294967295; x++; putn(x);'
body  dec-borrows      4294967295  'long x = 4294967296; x--; putn(x);'
body  pre-inc          4294967296  'long x = 4294967295; putn(++x);'
body  post-inc         "$(printf '4294967295\n4294967296')" 'long x = 4294967295; putn(x++); putn(x);'
body  plus-eq          4294967296  'long x = 4294967295; x += 1; putn(x);'
body  minus-eq         4294967295  'long x = 4294967296; x -= 1; putn(x);'
body  times-eq         10000000000 'long x = 100000; x *= 100000; putn(x);'
body  div-eq           3333333333  'long x = 10000000000; x /= 3; putn(x);'
body  mod-eq           4           'long x = 10000000000; x %= 7; putn(x);'
body  plus-eq-int      5000000007  'long x = 5000000000; int y = 7; x += y; putn(x);'
body  minus-eq-int     4999999993  'long x = 5000000000; int y = 7; x -= y; putn(x);'
body  times-eq-int     35000000000 'long x = 5000000000; int y = 7; x *= y; putn(x);'
body  div-eq-int       714285714   'long x = 5000000000; int y = 7; x /= y; putn(x);'
body  mod-eq-int       2           'long x = 5000000000; int y = 7; x %= y; putn(x);'
body  plus-eq-negative 7           'long x = 10; int y = -3; x += y; putn(x);'
body  int-plus-eq-long 15          'int x = 10; long y = 5; x += y; putn(x);'
body  int-times-eq-long 50         'int x = 10; long y = 5; x *= y; putn(x);'

# neighbours don't clobber each other
body  locals-dont-overlap "$(printf -- '-1\n7\n-1')" 'long a = -1; int b = 7; long c = -1; putn(a); putn(b); putn(c);'
body  locals-write-order  "$(printf -- '-1\n7\n-2')" 'long a; int b; long c; c = -2; b = 7; a = -1; putn(a); putn(b); putn(c);'

# longer-running
body  sum-long-loop    5000050000  'long s = 0; for (long i = 1; i <= 100000; i++) s += i; putn(s);'
body  power-of-two     4611686018427387904 'long p = 1; for (int i = 0; i < 62; i++) p *= 2; putn(p);'
body  fibonacci-90     2880067194370816120 'long a = 0; long b = 1; for (int i = 0; i < 90; i++) { long t = a + b; a = b; b = t; } putn(a);'
body  collatz-837799   524         'long n = 837799; int c = 0; while (n != 1) { if (n % 2) n = 3 * n + 1; else n = n / 2; c++; } putn(c);'

# functions
prog return-long 5000000000 <<'EOC'
long big() { return 5000000000; }
int main() { putn(big()); return 0; }
EOC

prog long-param 6000000000 <<'EOC'
long twice(long x) { return x * 2; }
int main() { putn(twice(3000000000)); return 0; }
EOC

prog int-arg-widened -7 <<'EOC'
long f(long x) { return x; }
int main() { int a = -7; putn(f(a)); return 0; }
EOC

prog long-arg-narrowed 1 <<'EOC'
int f(int x) { return x; }
int main() { long a = 4294967297; putn(f(a)); return 0; }
EOC

prog return-narrows 3 <<'EOC'
int f() { long a = 4294967299; return a; }
int main() { putn(f()); return 0; }
EOC

prog return-widens -9 <<'EOC'
long f() { int a = -9; return a; }
int main() { putn(f()); return 0; }
EOC

prog mixed-params 5000000003 <<'EOC'
long f(int a, long b, int c) { return a + b + c; }
int main() { putn(f(1, 5000000000, 2)); return 0; }
EOC

prog param-order 1000000000 <<'EOC'
long f(long a, long b) { return a - b; }
int main() { putn(f(5000000000, 4000000000)); return 0; }
EOC

prog param-order-reversed -1000000000 <<'EOC'
long f(long a, long b) { return a - b; }
int main() { putn(f(4000000000, 5000000000)); return 0; }
EOC

prog param-modified 4294967297 <<'EOC'
long f(long x) { x += 4294967296; return x; }
int main() { putn(f(1)); return 0; }
EOC

prog twelve-mixed 78 <<'EOC'
long f(long a, int b, long c, int d, long e, int g, long h, int i, long j, int k, long l, int m) {
    return a + b + c + d + e + g + h + i + j + k + l + m;
}
int main() { putn(f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)); return 0; }
EOC

prog void-long-param 5000000000 <<'EOC'
void show(long x) { putn(x); }
int main() { show(5000000000); return 0; }
EOC

prog factorial-20 2432902008176640000 <<'EOC'
long fact(long n) { if (n <= 1) return 1; return n * fact(n - 1); }
int main() { putn(fact(20)); return 0; }
EOC

prog fibonacci-recursive 6765 <<'EOC'
long fib(long n) { if (n < 2) return n; return fib(n - 1) + fib(n - 2); }
int main() { putn(fib(20)); return 0; }
EOC

prog calls-in-args 12000000000 <<'EOC'
long mul(long a, long b) { return a * b; }
long add(long a, long b) { return a + b; }
int main() { putn(mul(add(1000000000, 1000000000), add(2, 4))); return 0; }
EOC

prog prototype-long 4294967296 <<'EOC'
long later(long);
int main() { putn(later(2147483648)); return 0; }
long later(long x) { return x * 2; }
EOC

exits exit-code-from-long 7 <<'EOC'
int main() { long x = 4294967296 + 7; return x; }
EOC

# globals
prog global-long 5000000000 <<'EOC'
long g = 5000000000;
int main() { putn(g); return 0; }
EOC

prog global-long-negative -5000000000 <<'EOC'
long g = -5000000000;
int main() { putn(g); return 0; }
EOC

prog global-long-zero 0 <<'EOC'
long g;
int main() { putn(g); return 0; }
EOC

prog global-long-assign 4294967296 <<'EOC'
long g;
int main() { g = 4294967296; putn(g); return 0; }
EOC

prog global-long-inc 4294967296 <<'EOC'
long g = 4294967295;
int main() { g++; putn(g); return 0; }
EOC

prog global-long-compound "$(printf '10000000000\n3333333333\n1')" <<'EOC'
long g = 100000;
int main() { g *= 100000; putn(g); g /= 3; putn(g); g %= 7; putn(g); return 0; }
EOC

prog globals-mixed "$(printf '1\n5000000000\n2\n5000000003')" <<'EOC'
int a = 1;
long b = 5000000000;
int c = 2;
long d;
int main() { d = a + b + c; putn(a); putn(b); putn(c); putn(d); return 0; }
EOC

prog globals-zeroed-mixed "$(printf -- '-1\n7\n-1\n9')" <<'EOC'
long a;
int b;
long c;
int d;
int main() { a = -1; b = 7; c = -1; d = 9; putn(a); putn(b); putn(c); putn(d); return 0; }
EOC

prog globals-initial-mixed "$(printf '3\n4000000000\n5\n6000000000')" <<'EOC'
int a = 3;
long b = 4000000000;
int c = 5;
long d = 6000000000;
int main() { putn(a); putn(b); putn(c); putn(d); return 0; }
EOC

prog global-long-with-strings "$(printf 'hi\n5000000000\nthere\n0')" <<'EOC'
long g = 5000000000;
long z;
int main() { puts("hi"); putn(g); puts("there"); putn(z); return 0; }
EOC

prog global-hidden-by-local "$(printf '3\n5000000000')" <<'EOC'
long x = 5000000000;
long get() { return x; }
int main() { long x = 3; putn(x); putn(get()); return 0; }
EOC

# things mcc must refuse
refuse prototype-int-vs-long <<'EOC'
int f(long a);
int f(int a) { return a; }
int main() { return 0; }
EOC
refuse prototype-return-type <<'EOC'
long f();
int f() { return 1; }
int main() { return 0; }
EOC
refuse long-variable-void <<'EOC'
void long_g;
int main() { return 0; }
EOC
refuse global-long-not-constant <<'EOC'
long a = 1;
long g = a;
int main() { return 0; }
EOC
refuse long-no-name <<'EOC'
long = 5;
int main() { return 0; }
EOC
refuse long-missing-value <<'EOC'
int main() { long x = ; return 0; }
EOC
refuse long-redeclared <<'EOC'
int main() { long x; int x; return 0; }
EOC

finish