# && || !   (results are always exactly 1 or 0, and the right side is skipped when the left decides it)
. "$(dirname "$0")/lib.sh"

body  and-tt       1 'putn(1 && 1);'
body  and-tf       0 'putn(1 && 0);'
body  and-ft       0 'putn(0 && 1);'
body  and-ff       0 'putn(0 && 0);'
body  or-tt        1 'putn(1 || 1);'
body  or-tf        1 'putn(1 || 0);'
body  or-ft        1 'putn(0 || 1);'
body  or-ff        0 'putn(0 || 0);'
body  not-zero     1 'putn(!0);'
body  not-one      0 'putn(!1);'
body  not-five     0 'putn(!5);'
body  not-negative 0 'putn(!-1);'
body  not-not      1 'putn(!!5);'
body  not-not-zero 0 'putn(!!0);'

# the answer is 1 or 0, never the operand itself
body  and-gives-1  1 'putn(5 && 7);'
body  or-gives-1   1 'putn(0 || 9);'
body  or-gives-1b  1 'putn(2 || 0);'

# precedence: ! binds tightest, then && then ||
body  and-before-or   1 'putn(1 || 0 && 0);'
body  and-before-or2  1 'putn(0 && 0 || 1);'
body  brackets-first  0 'putn((1 || 0) && 0);'
body  not-before-eq   1 'putn(!3 == 0);'
body  not-brackets    0 'putn(!(3 > 2));'
body  minus-not       -1 'putn(-!0);'
body  maths-first     0 'putn(1 + 1 && 0);'
body  maths-right     1 'putn(1 && 2 + 3);'
body  compare-inside  1 'int x = 5; putn(x > 1 && x < 10);'
body  compare-or      0 'int x = 5; putn(x < 1 || x > 10);'
body  not-and         1 'putn(!0 && !0);'

body  chain-and-true  1 'putn(1 && 2 && 3 && 4);'
body  chain-and-false 0 'putn(1 && 2 && 0 && 4);'
body  chain-or-true   1 'putn(0 || 0 || 0 || 5);'
body  chain-or-false  0 'putn(0 || 0 || 0);'
body  mixed-chain     1 'putn(0 || 0 && 1 || 1 && 1);'

# short circuit: the right side would crash if it ran (divide by zero)
body  and-skips    0 'int z = 0; putn(z && 10 / z);'
body  or-skips     1 'int z = 0; putn(1 || 10 % z);'
body  and-guard    1 'int z = 5; putn(z && 10 / z);'
body  or-guard     1 'int z = 0; putn(z || 10 / 10);'

body  as-value     1 'int a = (1 < 2) && (2 < 3); putn(a);'
body  value-plus   2 'int a = 3 && 4; putn(a + 1);'
body  two-vars     "$(printf '0\n1')" 'int a = 1; int b = 0; putn(a && b); putn(a || b);'
body  in-if        1 'int x = 3; if (x > 1 && x < 5) putn(1); else putn(0);'
body  in-if-not    1 'int x = 0; if (!x) putn(1); else putn(0);'
body  in-while     4 'int i = 0; while (i < 10 && i != 4) i = i + 1; putn(i);'
body  prime-17     1 'int n = 17; int d = 2; int p = 1; while (d * d <= n && p) { if (n % d == 0) p = 0; d = d + 1; } putn(p);'
body  prime-15     0 'int n = 15; int d = 2; int p = 1; while (d * d <= n && p) { if (n % d == 0) p = 0; d = d + 1; } putn(p);'

# long chains: 33 operands is the most mcc allows
and33=1; or33=0; and41=1; or41=0
i=0; while [ $i -lt 32 ]; do and33="$and33 && 1"; or33="$or33 || 0"; i=$((i + 1)); done
i=0; while [ $i -lt 40 ]; do and41="$and41 && 1"; or41="$or41 || 0"; i=$((i + 1)); done
body  and-33       1 "putn($and33);"
body  or-33        0 "putn($or33);"
fails and-too-long   "putn($and41);"
fails or-too-long    "putn($or41);"

finish