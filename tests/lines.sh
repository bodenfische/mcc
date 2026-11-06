# error messages say which line the problem is on
. "$(dirname "$0")/lib.sh"

cat > "$tmp/a.c" <<'EOC'
int main() {
    putn(1);
    putn(2 +);
    return 0;
}
EOC
says expression-line-3 "$tmp/a.c" "mcc: line 3: expected expression"

cat > "$tmp/b.c" <<'EOC'
int main() {
    int x = 1;

    putn(y);
}
EOC
says undeclared-line-4 "$tmp/b.c" "mcc: line 4: undeclared 'y'"

printf 'int main( {\n' > "$tmp/c.c"
says first-line "$tmp/c.c" "mcc: line 1: expected ')'"

cat > "$tmp/d.c" <<'EOC'
// comment
/* spans
   two lines */
int main() { putn(1) }
EOC
says after-comments "$tmp/d.c" "mcc: line 4: expected ';'"

cat > "$tmp/e.c" <<'EOC'
int main() {
    /* oops
    return 0;
}
EOC
says comment-start "$tmp/e.c" "mcc: line 2: unterminated comment"

cat > "$tmp/f.c" <<'EOC'
int main() {
    int i = 0;
    while (i < 3) {
        i = i + 1;
        if (i == 2) {
            putn(z);
        }
    }
}
EOC
says deep-inside "$tmp/f.c" "mcc: line 6: undeclared 'z'"

cat > "$tmp/g.c" <<'EOC'
int main() {
    int x;
    int x;
}
EOC
says redeclared "$tmp/g.c" "mcc: line 3: already declared 'x'"

says missing-file "$tmp/nothere.c" "mcc: cannot open '$tmp/nothere.c'"

finish