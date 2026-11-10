# pointers: int * and long * (and pointers to pointers), & and *
. "$(dirname "$0")/lib.sh"

# & and * on locals
body  addr-deref        5          'int x = 5; int *p = &x; putn(*p);'
body  write-through     9          'int x = 5; int *p = &x; *p = 9; putn(x);'
body  long-through      5000000000 'long x = 5; long *p = &x; *p = 5000000000; putn(x);'
body  read-long         -7         'long x = -7; long *p = &x; putn(*p);'
body  deref-neg-int     -7         'int x = -7; int *p = &x; putn(*p);'
body  int-write-keeps-neighbour "$(printf '1\n2')" 'int a = 1; int b = 2; int *p = &a; *p = 1; putn(a); putn(b);'
body  star-spaced       6          'int x = 6; int * p = &x; putn(* p);'
body  star-no-space     6          'int x = 6; int*p = &x; putn(*p);'
body  two-pointers      "$(printf '3\n3')" 'int x = 3; int *p = &x; int *q = p; putn(*p); putn(*q);'
body  pointer-reassign  "$(printf '1\n2')" 'int a = 1; int b = 2; int *p = &a; putn(*p); p = &b; putn(*p);'
body  deref-in-expr     17         'int x = 5; int *p = &x; putn(*p * 3 + 2);'
body  deref-minus       -5         'int x = 5; int *p = &x; putn(-*p);'
body  deref-not         "$(printf '0\n1')" 'int x = 5; int y = 0; int *p = &x; int *q = &y; putn(!*p); putn(!*q);'
body  deref-two-sides   10         'int a = 4; int b = 6; int *p = &a; int *q = &b; putn(*p + *q);'
body  deref-compare     1          'int a = 4; int b = 6; int *p = &a; int *q = &b; putn(*p < *q);'

# assignment forms through a pointer
body  plus-eq           8          'int x = 5; int *p = &x; *p += 3; putn(x);'
body  minus-eq          2          'int x = 5; int *p = &x; *p -= 3; putn(x);'
body  times-eq          15         'int x = 5; int *p = &x; *p *= 3; putn(x);'
body  div-eq            2          'int x = 7; int *p = &x; *p /= 3; putn(x);'
body  mod-eq            1          'int x = 7; int *p = &x; *p %= 3; putn(x);'
body  neg-div-eq        -2         'int x = -7; int *p = &x; *p /= 3; putn(x);'
body  neg-mod-eq        -1         'int x = -7; int *p = &x; *p %= 3; putn(x);'
body  long-plus-eq      5000000007 'long x = 5000000000; long *p = &x; *p += 7; putn(x);'
body  long-times-eq     35000000000 'long x = 5000000000; long *p = &x; *p *= 7; putn(x);'
body  long-div-eq       714285714  'long x = 5000000000; long *p = &x; *p /= 7; putn(x);'
body  long-mod-eq       2          'long x = 5000000000; long *p = &x; *p %= 7; putn(x);'
body  int-long-widen    5000000000 'long x = 0; long *p = &x; int y = 7; *p = 5000000000; *p += y - 7; putn(x);'
body  narrowing-write   1          'int x = 0; int *p = &x; long big = 4294967297; *p = big; putn(x);'
body  value-uses-self   12         'int x = 5; int *p = &x; *p = *p + 7; putn(x);'
body  value-has-call    12         'int x = 5; int *p = &x; *p = x + 7; putn(*p);'

# pointers to pointers
body  ptr-to-ptr        5          'int x = 5; int *p = &x; int **pp = &p; putn(**pp);'
body  ptr-to-ptr-write  8          'int x = 5; int *p = &x; int **pp = &p; **pp = 8; putn(x);'
body  ptr-to-ptr-move   2          'int a = 1; int b = 2; int *p = &a; int **pp = &p; *pp = &b; putn(*p);'
body  triple            4          'int x = 4; int *p = &x; int **q = &p; int ***r = &q; putn(***r);'
body  long-ptr-ptr      -4         'long x = -4; long *p = &x; long **q = &p; putn(**q);'

# pointer arithmetic is scaled by the size of what it points at
body  inc-int           1          'int a = 7; int b = 8; int *p = &b; p++; putn(p - &b);'
body  diff-int          "$(printf '2\n-2')" 'int a = 0; int *p = &a; int *q = p + 2; putn(q - p); putn(p - q);'
body  diff-long         "$(printf '3\n-3')" 'long a = 0; long *p = &a; long *q = p + 3; putn(q - p); putn(p - q);'
body  plus-long-count   "$(printf '5000000000')" 'int a = 0; int *p = &a; long n = 5000000000; int *q = p + n; putn(q - p);'
body  int-plus-ptr      4          'int a = 0; int *p = &a; int *q = 4 + p; putn(q - p);'
body  minus-int         "$(printf -- '-2')" 'int a = 0; int *p = &a; int *q = p - 2; putn(q - p);'
body  plus-negative     -3         'int a = 0; int *p = &a; int *q = p + -3; putn(q - p);'
body  ptr-eq-plus       "$(printf '6\n3')" 'long a = 0; long *p = &a; p += 6; putn(p - &a); p -= 3; putn(p - &a);'
body  int-ptr-eq        "$(printf '4\n1')" 'int a = 0; int *p = &a; p += 4; putn(p - &a); p -= 3; putn(p - &a);'
body  ptr-inc-dec       "$(printf '1\n2\n1\n0')" 'int a = 0; int *p = &a; ++p; putn(p - &a); p++; putn(p - &a); --p; putn(p - &a); p--; putn(p - &a);'
body  ptr-post-value    "$(printf '0\n1')" 'int a = 0; int *p = &a; putn(p++ - &a); putn(p - &a);'
body  ptr-to-ptr-step   "$(printf '2')" 'int *a = 0; int **p = &a; int **q = p + 2; putn(q - p);'

# comparing pointers
body  eq-same           "$(printf '1\n0')" 'int x = 0; int *p = &x; int *q = &x; putn(p == q); putn(p != q);'
body  eq-different      "$(printf '0\n1')" 'int x = 0; int y = 0; int *p = &x; int *q = &y; putn(p == q); putn(p != q);'
body  order             "$(printf '1\n0')" 'int x = 0; int *p = &x; int *q = p + 1; putn(p < q); putn(p > q);'
body  order-eq          "$(printf '1\n1\n0')" 'int x = 0; int *p = &x; int *q = p + 1; putn(p <= q); putn(q >= p); putn(q <= p);'
body  against-zero      "$(printf '0\n1')" 'int x = 0; int *p = &x; putn(p == 0); putn(p != 0);'
body  zero-on-left      "$(printf '0\n1')" 'int x = 0; int *p = &x; putn(0 == p); putn(0 != p);'
body  null-pointer      "$(printf '1\n0')" 'int *p = 0; putn(p == 0); putn(p != 0);'
body  null-assign       1          'int x = 0; int *p = &x; p = 0; putn(!p);'

# pointers as conditions
body  cond-true         1          'int x = 0; int *p = &x; if (p) putn(1); else putn(0);'
body  cond-null         0          'int *p = 0; if (p) putn(1); else putn(0);'
body  not-ptr           "$(printf '0\n1')" 'int x = 0; int *p = &x; int *q = 0; putn(!p); putn(!q);'
body  and-or            "$(printf '1\n0\n1')" 'int x = 0; int *p = &x; int *q = 0; putn(p && 1); putn(q && 1); putn(q || p);'
body  while-ptr         3          'int a = 0; int *p = &a; int n = 0; while (p) { n++; if (n == 3) p = 0; } putn(n);'
body  walk-with-ptr     10         'int a = 0; int *p = &a; int *end = p + 5; int n = 0; while (p != end) { n += 2; p++; } putn(n);'

# functions
prog param-write 9 <<'EOC'
void set(int *p, int v) { *p = v; }
int main() { int x = 1; set(&x, 9); putn(x); return 0; }
EOC

prog swap "$(printf '2\n1')" <<'EOC'
void swap(int *a, int *b) { int t = *a; *a = *b; *b = t; }
int main() { int x = 1; int y = 2; swap(&x, &y); putn(x); putn(y); return 0; }
EOC

prog swap-long "$(printf '5000000000\n1')" <<'EOC'
void swap(long *a, long *b) { long t = *a; *a = *b; *b = t; }
int main() { long x = 1; long y = 5000000000; swap(&x, &y); putn(x); putn(y); return 0; }
EOC

prog return-pointer 7 <<'EOC'
int *pick(int *a, int *b, int which) { if (which) return a; return b; }
int main() { int x = 7; int y = 8; putn(*pick(&x, &y, 1)); return 0; }
EOC

prog return-pointer-other 8 <<'EOC'
int *pick(int *a, int *b, int which) { if (which) return a; return b; }
int main() { int x = 7; int y = 8; putn(*pick(&x, &y, 0)); return 0; }
EOC

prog return-null 1 <<'EOC'
int *none() { return 0; }
int main() { int *p = none(); putn(p == 0); return 0; }
EOC

prog write-through-call 5 <<'EOC'
int g;
int *where() { return &g; }
int main() { *where() = 5; putn(g); return 0; }
EOC

prog ptr-param-mixed 12 <<'EOC'
long add(int a, long *p, int b) { return a + *p + b; }
int main() { long x = 9; putn(add(1, &x, 2)); return 0; }
EOC

prog pass-pointer-on 6 <<'EOC'
void inner(int *p) { *p = *p + 1; }
void outer(int *p) { inner(p); inner(p); }
int main() { int x = 4; outer(&x); putn(x); return 0; }
EOC

prog param-address 4 <<'EOC'
int bump(int n) { int *p = &n; *p += 1; return n; }
int main() { putn(bump(3)); return 0; }
EOC

prog param-pointer-moves "$(printf '3\n0')" <<'EOC'
long dist(int *a, int *b) { return b - a; }
int main() { int x = 0; int *p = &x; putn(dist(p, p + 3)); putn(dist(p, p)); return 0; }
EOC

prog recursion-through-pointer 120 <<'EOC'
void fact(int n, int *acc) { if (n < 2) return; *acc *= n; fact(n - 1, acc); }
int main() { int r = 1; fact(5, &r); putn(r); return 0; }
EOC

prog prototype-pointer 4 <<'EOC'
void inc(int *p);
int main() { int x = 3; inc(&x); putn(x); return 0; }
void inc(int *p) { *p += 1; }
EOC

prog prototype-unnamed-pointer 4 <<'EOC'
void inc(int *);
int main() { int x = 3; inc(&x); putn(x); return 0; }
void inc(int *p) { *p += 1; }
EOC

prog ptr-ptr-param 5 <<'EOC'
void point(int **pp, int *to) { *pp = to; }
int main() { int x = 5; int *p = 0; point(&p, &x); putn(*p); return 0; }
EOC

prog out-params "$(printf '7\n2')" <<'EOC'
void divmod(int a, int b, int *q, int *r) { *q = a / b; *r = a % b; }
int main() { int q; int r; divmod(23, 3, &q, &r); putn(q); putn(r); return 0; }
EOC

prog caller-locals-intact "$(printf '1\n2\n3')" <<'EOC'
void clobber(int *p) { *p = 3; }
int main() { int a = 1; int b = 2; int c = 0; clobber(&c); putn(a); putn(b); putn(c); return 0; }
EOC

# globals
prog address-of-global 5 <<'EOC'
int g;
int main() { int *p = &g; *p = 5; putn(g); return 0; }
EOC

prog address-of-global-long 5000000000 <<'EOC'
long g = 1;
int main() { long *p = &g; *p = 5000000000; putn(g); return 0; }
EOC

prog global-pointer 5 <<'EOC'
int x;
int *gp;
int main() { x = 5; gp = &x; putn(*gp); return 0; }
EOC

prog global-pointer-starts-null "$(printf '1\n5')" <<'EOC'
int x = 5;
int *gp = 0;
int main() { putn(gp == 0); gp = &x; putn(*gp); return 0; }
EOC

prog global-pointer-unset 1 <<'EOC'
int *gp;
int main() { putn(gp == 0); return 0; }
EOC

prog global-ptr-ptr 9 <<'EOC'
int x = 9;
int *p;
int **pp;
int main() { p = &x; pp = &p; putn(**pp); return 0; }
EOC

prog global-pointer-aligned "$(printf '1\n5\n2')" <<'EOC'
int a;
int *gp;
int b;
int main() { a = 1; b = 2; gp = &a; *gp = 1; putn(a); gp = &b; putn(5); putn(*gp); return 0; }
EOC

prog global-pointer-steps 3 <<'EOC'
int a;
int *gp;
int main() { gp = &a; gp += 3; putn(gp - &a); return 0; }
EOC

prog global-pointer-incdec "$(printf '1\n0')" <<'EOC'
long a;
long *gp;
int main() { gp = &a; gp++; putn(gp - &a); gp--; putn(gp - &a); return 0; }
EOC

# scope
prog block-scope-pointer 5 <<'EOC'
int main() { int x = 5; int *p = &x; { int y = 6; int *q = &y; *q = 7; } putn(*p); return 0; }
EOC

prog inner-pointer-outer-var 8 <<'EOC'
int main() { int x = 5; { int *p = &x; *p = 8; } putn(x); return 0; }
EOC

prog for-with-pointer 10 <<'EOC'
int main() { int s = 0; int *p = &s; for (int i = 1; i <= 4; i++) *p += i; putn(s); return 0; }
EOC

prog for-pointer-loop-var 5 <<'EOC'
int main() { int a = 0; int n = 0; for (int *p = &a; p != &a + 5; p++) n++; putn(n); return 0; }
EOC

# things mcc must refuse
refuse deref-int <<'EOC'
int main() { int x = 1; putn(*x); return 0; }
EOC
refuse deref-long <<'EOC'
int main() { long x = 1; putn(*x); return 0; }
EOC
refuse store-through-int <<'EOC'
int main() { int x = 1; *x = 2; return 0; }
EOC
refuse deref-twice-too-far <<'EOC'
int main() { int x = 1; int *p = &x; putn(**p); return 0; }
EOC
refuse address-of-number <<'EOC'
int main() { int *p = &5; return 0; }
EOC
refuse address-of-missing <<'EOC'
int main() { int *p = &nothing; return 0; }
EOC
refuse int-from-pointer <<'EOC'
int main() { int x = 1; int *p = &x; int y = p; return 0; }
EOC
refuse long-from-pointer <<'EOC'
int main() { int x = 1; long y = &x; return 0; }
EOC
refuse pointer-from-int <<'EOC'
int main() { int x = 1; int *p = x; return 0; }
EOC
refuse pointer-from-one <<'EOC'
int main() { int *p = 1; return 0; }
EOC
refuse pointer-from-long <<'EOC'
int main() { long x = 0; int *p = x; return 0; }
EOC
refuse wrong-pointer-type <<'EOC'
int main() { long x = 1; int *p = &x; return 0; }
EOC
refuse wrong-pointer-assign <<'EOC'
int main() { int x = 1; long y = 2; int *p = &x; long *q = &y; p = q; return 0; }
EOC
refuse depth-mismatch <<'EOC'
int main() { int x = 1; int *p = &x; int **pp = p; return 0; }
EOC
refuse pass-wrong-pointer <<'EOC'
void f(long *p) { }
int main() { int x = 1; f(&x); return 0; }
EOC
refuse pass-int-as-pointer <<'EOC'
void f(int *p) { }
int main() { f(3); return 0; }
EOC
refuse pass-pointer-as-int <<'EOC'
void f(int a) { }
int main() { int x = 1; f(&x); return 0; }
EOC
refuse return-int-as-pointer <<'EOC'
int *f() { return 5; }
int main() { return 0; }
EOC
refuse return-pointer-as-int <<'EOC'
int f() { int x = 1; return &x; }
int main() { return 0; }
EOC
refuse add-two-pointers <<'EOC'
int main() { int x = 1; int *p = &x; int *q = p + p; return 0; }
EOC
refuse int-minus-pointer <<'EOC'
int main() { int x = 1; int *p = &x; int *q = 1 - p; return 0; }
EOC
refuse subtract-different-pointers <<'EOC'
int main() { int x = 1; long y = 1; int *p = &x; long *q = &y; putn(p - q); return 0; }
EOC
refuse multiply-pointer <<'EOC'
int main() { int x = 1; int *p = &x; putn(p * 2); return 0; }
EOC
refuse divide-pointer <<'EOC'
int main() { int x = 1; int *p = &x; putn(p / 2); return 0; }
EOC
refuse remainder-pointer <<'EOC'
int main() { int x = 1; int *p = &x; putn(p % 2); return 0; }
EOC
refuse negate-pointer <<'EOC'
int main() { int x = 1; int *p = &x; putn(-p); return 0; }
EOC
refuse times-eq-pointer <<'EOC'
int main() { int x = 1; int *p = &x; p *= 2; return 0; }
EOC
refuse plus-eq-pointer-pointer <<'EOC'
int main() { int x = 1; int *p = &x; p += p; return 0; }
EOC
refuse plus-eq-through-wrong <<'EOC'
int main() { int x = 1; int *p = &x; int **pp = &p; *pp *= 2; return 0; }
EOC
refuse compare-with-one <<'EOC'
int main() { int x = 1; int *p = &x; putn(p == 1); return 0; }
EOC
refuse compare-with-int-var <<'EOC'
int main() { int x = 1; int *p = &x; putn(p == x); return 0; }
EOC
refuse compare-different-pointers <<'EOC'
int main() { int x = 1; long y = 1; int *p = &x; long *q = &y; putn(p == q); return 0; }
EOC
refuse print-pointer <<'EOC'
int main() { int x = 1; putn(&x); return 0; }
EOC
refuse void-pointer <<'EOC'
int main() { void *p; return 0; }
EOC
refuse void-pointer-param <<'EOC'
void f(void *p) { }
int main() { return 0; }
EOC
refuse global-pointer-nonzero <<'EOC'
int *p = 5;
int main() { return 0; }
EOC
refuse prototype-pointer-mismatch <<'EOC'
void f(int *p);
void f(long *p) { }
int main() { return 0; }
EOC
refuse prototype-pointer-vs-int <<'EOC'
void f(int *p);
void f(int p) { }
int main() { return 0; }
EOC
refuse return-type-pointer-mismatch <<'EOC'
int *f();
long *f() { return 0; }
int main() { return 0; }
EOC
refuse star-without-operand <<'EOC'
int main() { int x = *; return 0; }
EOC
refuse ampersand-without-operand <<'EOC'
int main() { int *p = &; return 0; }
EOC
refuse pointer-redeclared <<'EOC'
int main() { int *p; int p; return 0; }
EOC

finish