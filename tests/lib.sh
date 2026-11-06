# Helpers for the test files. Each test file starts with:  . "$(dirname "$0")/lib.sh"
# and ends with:  finish
#
# Tests are real C. As well as mcc, gcc builds each one (with putn defined as a
# printf) and must print the same thing, so a wrong expected value can't sneak in.

cd "$(dirname "$0")/.." || exit 1
[ -n "$MCC_BUILT" ] || gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c || exit 1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0
fail=0

# run a test program, giving up after 5 seconds in case a loop never ends
run() {
    if command -v timeout >/dev/null 2>&1; then timeout 5 "$@"; else "$@"; fi
}

# check NAME EXPECTED-OUTPUT FILE.c
check() {
    ok=1
    ./mcc "$3" "$tmp/t" && [ "$(run "$tmp/t")" = "$2" ] || ok=0
    gcc -w -include stdio.h '-Dputn(x)=printf("%d\n",(x))' -o "$tmp/g" "$3" \
        && [ "$(run "$tmp/g")" = "$2" ] || ok=0
    if [ "$ok" = 1 ]; then
        echo "ok   $1"; pass=$((pass + 1))
    else
        echo "FAIL $1"; fail=$((fail + 1))
    fi
}

# body NAME EXPECTED-OUTPUT STATEMENTS   (wrapped in int main() { ... return 0; })
body() {
    printf 'int main() { %s return 0; }\n' "$3" > "$tmp/t.c"
    check "$1" "$2" "$tmp/t.c"
}

# fails NAME STATEMENTS   (mcc must refuse these)
fails() {
    printf 'int main() { %s return 0; }\n' "$2" > "$tmp/t.c"
    if ./mcc "$tmp/t.c" "$tmp/t" 2>/dev/null; then
        echo "FAIL $1"; fail=$((fail + 1))
    else
        echo "ok   $1"; pass=$((pass + 1))
    fi
}

# says NAME FILE.c MESSAGE   (mcc must fail with exactly this message)
says() {
    got=$(./mcc "$2" "$tmp/t" 2>&1); status=$?
    if [ "$status" != 0 ] && [ "$got" = "$3" ]; then
        echo "ok   $1"; pass=$((pass + 1))
    else
        echo "FAIL $1 (got: $got)"; fail=$((fail + 1))
    fi
}

finish() {
    echo "$pass passed, $fail failed"
    [ "$fail" = 0 ]
}