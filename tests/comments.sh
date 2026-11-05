# // and /* */ comments
. "$(dirname "$0")/lib.sh"

body  line-comment     "$(printf '1\n2')" "putn(1); // putn(9);
putn(2);"
body  block-comment    1  'putn(1); /* putn(9); */'
body  inside-expr      3  'putn(1 /* one */ + /* two */ 2);'
body  no-spaces        3  'putn(1+/**/2);'
body  multi-line       "$(printf '1\n2')" 'putn(1); /* putn(9);
   putn(8); */ putn(2);'
body  stars-inside     "$(printf '1\n2')" 'putn(1); /* * ** / */ putn(2);'
body  before-else      2  'if (0) putn(1); /* skipped */ else putn(2);'
body  after-decl       5  'int x = 5; // five
putn(x);'
body  divide-is-fine   2  'putn(4 / 2);'
body  divide-then-mul  4  'int x = 6; putn(x / 3 * 2);'
body  in-string        "$(printf '// not a comment\n/* nor this */')" 'puts("// not a comment"); puts("/* nor this */");'

cat > "$tmp/c.c" <<'EOC'
// a whole file with comments
/* header
   block */
int main() { // start
    int x = 4; /* four */
    putn(x); // prints 4
    return 0; /* done */
}
// trailing line
EOC
check whole-file 4 "$tmp/c.c"

printf 'int main() { putn(7); return 0; } // no newline at the end' > "$tmp/d.c"
check ends-in-comment 7 "$tmp/d.c"

finish