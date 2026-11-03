#!/bin/sh
# Builds mcc with gcc once, then runs every test file in this folder.
# Run from anywhere:  sh tests/run.sh
# Or one area on its own:  sh tests/vars.sh

cd "$(dirname "$0")/.." || exit 1
gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c || exit 1
export MCC_BUILT=1

bad=0
for f in tests/*.sh; do
    case $f in */run.sh | */lib.sh) continue ;; esac
    echo "== $(basename "$f" .sh)"
    sh "$f" || bad=$((bad + 1))
done

echo
[ "$bad" = 0 ] && echo "all passed" || echo "$bad test file(s) failed"
[ "$bad" = 0 ]