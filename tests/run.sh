#!/bin/sh
# Builds mcc with gcc, then compiles and runs every test and checks what it prints.
# A test is NAME.expect (what it should print) plus NAME.c, found in tests/ or examples/.
# Run from anywhere:  sh tests/run.sh

cd "$(dirname "$0")/.." || exit 1
gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c || exit 1

pass=0
fail=0
for expect in tests/*.expect; do
    name=$(basename "$expect" .expect)
    src=tests/$name.c
    [ -f "$src" ] || src=examples/$name.c
    if ./mcc "$src" "tests/$name.bin" && "./tests/$name.bin" | cmp -s - "$expect"; then
        echo "ok   $name"
        pass=$((pass + 1))
    else
        echo "FAIL $name"
        fail=$((fail + 1))
    fi
    rm -f "tests/$name.bin"
done

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]