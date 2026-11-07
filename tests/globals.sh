# global variables
. "$(dirname "$0")/lib.sh"

prog default-zero 0 <<'EOC'
int g;
int main() { putn(g); return 0; }
EOC

prog initial-value 5 <<'EOC'
int g = 5;
int main() { putn(g); return 0; }
EOC

prog initial-negative -7 <<'EOC'
int g = -7;
int main() { putn(g); return 0; }
EOC

prog initial-hex 16 <<'EOC'
int g = 0x10;
int main() { putn(g); return 0; }
EOC

prog initial-char 65 <<'EOC'
int g = 'A';
int main() { putn(g); return 0; }
EOC

prog initial-zero 0 <<'EOC'
int g = 0;
int main() { putn(g); return 0; }
EOC

prog initial-int-min -2147483648 <<'EOC'
int g = -2147483648;
int main() { putn(g); return 0; }
EOC

prog assign 4 <<'EOC'
int g;
int main() { g = 4; putn(g); return 0; }
EOC

prog assign-over-initial "$(printf '5\n9')" <<'EOC'
int g = 5;
int main() { putn(g); g = 9; putn(g); return 0; }
EOC

prog compound-ops 2 <<'EOC'
int g = 10;
int main() { g += 5; g *= 2; g -= 1; g /= 3; g %= 7; putn(g); return 0; }
EOC

prog inc-dec "$(printf '5\n6\n7\n7\n5')" <<'EOC'
int g = 5;
int main() { putn(g++); putn(g); putn(++g); putn(g--); putn(--g); return 0; }
EOC

prog inc-dec-statements 6 <<'EOC'
int g = 5;
int main() { g++; g++; g--; ++g; --g; putn(g); return 0; }
EOC

prog in-expressions 17 <<'EOC'
int a = 3;
int b = 4;
int main() { putn(a * b + a + 2); return 0; }
EOC

prog in-conditions "$(printf '1\n0')" <<'EOC'
int flag = 1;
int main() {
    if (flag) putn(1); else putn(0);
    flag = 0;
    if (flag) putn(1); else putn(0);
    return 0;
}
EOC

# shared between functions
prog counter 3 <<'EOC'
int count;
void bump() { count++; }
int main() { bump(); bump(); bump(); putn(count); return 0; }
EOC

prog setter-getter 42 <<'EOC'
int stored;
void set(int v) { stored = v; }
int get() { return stored; }
int main() { set(42); putn(get()); return 0; }
EOC

prog accumulate 55 <<'EOC'
int total;
void add(int n) { total += n; }
int main() { for (int i = 1; i <= 10; i++) add(i); putn(total); return 0; }
EOC

prog counts-calls "$(printf '55\n177')" <<'EOC'
int calls;
int fib(int n) { calls++; if (n < 2) return n; return fib(n - 1) + fib(n - 2); }
int main() { putn(fib(10)); putn(calls); return 0; }
EOC

prog loop-variable "$(printf '0\n1\n2\n3')" <<'EOC'
int i;
int main() { for (i = 0; i < 3; i++) putn(i); putn(i); return 0; }
EOC

prog big-count 1000000 <<'EOC'
int n;
int main() { while (n < 1000000) n++; putn(n); return 0; }
EOC

prog several "$(printf '1\n0\n3\n4')" <<'EOC'
int a = 1;
int b;
int c = 3;
int d;
int main() { d = c + a; putn(a); putn(b); putn(c); putn(d); return 0; }
EOC

prog between-functions 9 <<'EOC'
int first() { return 4; }
int middle = 5;
int last() { return first() + middle; }
int main() { putn(last()); return 0; }
EOC

# locals and parameters hide globals of the same name
prog local-hides "$(printf '2\n1')" <<'EOC'
int x = 1;
int get() { return x; }
int main() { int x = 2; putn(x); putn(get()); return 0; }
EOC

prog param-hides "$(printf '50\n1')" <<'EOC'
int x = 1;
int f(int x) { return x * 10; }
int main() { putn(f(5)); putn(x); return 0; }
EOC

prog block-hides "$(printf '2\n1')" <<'EOC'
int x = 1;
int main() { { int x = 2; putn(x); } putn(x); return 0; }
EOC

prog local-change-leaves-global "$(printf '9\n1')" <<'EOC'
int x = 1;
int main() { int x = 1; x = 9; putn(x); { putn(0 * x + 1); } return 0; }
EOC

prog assign-global-from-inner-scope 7 <<'EOC'
int g;
int main() { { g = 7; } putn(g); return 0; }
EOC

# strings, data and zeroed memory sit side by side
prog with-strings "$(printf 'hi\n7\nthere\n0\n8')" <<'EOC'
int g = 7;
int z;
int main() { puts("hi"); putn(g); puts("there"); putn(z); z = g + 1; putn(z); return 0; }
EOC

prog odd-length-strings "$(printf 'a\n11\nbcd\n22')" <<'EOC'
int x = 11;
int y = 22;
int main() { puts("a"); putn(x); puts("bcd"); putn(y); return 0; }
EOC

prog value-after-a-string "$(printf 's1\n3\ns22\n4')" <<'EOC'
int a = 3;
void first() { puts("s1"); }
int b = 4;
int main() { first(); putn(a); puts("s22"); putn(b); return 0; }
EOC

# static is accepted
prog static-keyword 3 <<'EOC'
static int g = 3;
static int get() { return g; }
int main() { putn(get()); return 0; }
EOC

prog static-uninitialised 4 <<'EOC'
static int g;
int main() { g = 4; putn(g); return 0; }
EOC

# exit codes
exits global-exit-code 9 <<'EOC'
int g = 9;
int main() { return g; }
EOC

# plenty of globals
{
    i=0; while [ $i -lt 100 ]; do printf 'int g%d;\n' $i; i=$((i + 1)); done
    printf 'int main() {\n'
    i=0; while [ $i -lt 100 ]; do printf '    g%d = %d;\n' $i $i; i=$((i + 1)); done
    printf '    putn('
    i=0; while [ $i -lt 100 ]; do [ $i -gt 0 ] && printf ' + '; printf 'g%d' $i; i=$((i + 1)); done
    printf ');\n    return 0;\n}\n'
} | prog hundred-globals 4950

{
    i=0; while [ $i -lt 50 ]; do printf 'int h%d = %d;\n' $i $((i * 2)); i=$((i + 1)); done
    printf 'int main() { putn('
    i=0; while [ $i -lt 50 ]; do [ $i -gt 0 ] && printf ' + '; printf 'h%d' $i; i=$((i + 1)); done
    printf '); return 0; }\n'
} | prog fifty-initialised 2450

# things mcc must refuse
refuse use-before-declaration <<'EOC'
int main() { putn(g); return 0; }
int g;
EOC
refuse defined-twice <<'EOC'
int g;
int g;
int main() { return 0; }
EOC
refuse defined-twice-with-values <<'EOC'
int g = 1;
int g = 2;
int main() { return 0; }
EOC
refuse same-name-as-function <<'EOC'
int f() { return 1; }
int f;
int main() { return 0; }
EOC
refuse function-same-name-as-variable <<'EOC'
int f;
int f() { return 1; }
int main() { return 0; }
EOC
refuse void-variable <<'EOC'
void g;
int main() { return 0; }
EOC
refuse not-a-constant <<'EOC'
int a = 1;
int g = a;
int main() { return 0; }
EOC
refuse missing-value <<'EOC'
int g = ;
int main() { return 0; }
EOC
refuse missing-semicolon <<'EOC'
int g = 1
int main() { return 0; }
EOC
refuse undeclared-in-function <<'EOC'
int g;
int main() { putn(h); return 0; }
EOC
refuse called-like-function <<'EOC'
int g;
int main() { putn(g(1)); return 0; }
EOC

cat > "$tmp/m1.c" <<'EOC'
int g;
int g;
int main() { return 0; }
EOC
says defined-twice-message "$tmp/m1.c" "mcc: line 2: already defined 'g'"

cat > "$tmp/m2.c" <<'EOC'
int a;
int g = a;
int main() { return 0; }
EOC
says constant-message "$tmp/m2.c" "mcc: line 2: expected a constant"

cat > "$tmp/m3.c" <<'EOC'
int g = 1 + 2;
int main() { return 0; }
EOC
says one-number-message "$tmp/m3.c" "mcc: line 1: a global's starting value can only be a single number"

finish