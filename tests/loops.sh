# while loops
. "$(dirname "$0")/lib.sh"

body  count-up      "$(printf '0\n1\n2')"   'int i = 0; while (i < 3) { putn(i); i = i + 1; }'
body  count-down    "$(printf '3\n2\n1')"   'int i = 3; while (i > 0) { putn(i); i = i - 1; }'
body  never-runs    2   'while (0) putn(1); putn(2);'
body  runs-once     "$(printf '1\n2')"      'int i = 0; while (i < 1) { putn(1); i = i + 1; } putn(2);'
body  one-statement 0   'int i = 3; while (i) i = i - 1; putn(i);'
body  sum-to-ten    55  'int i = 1; int s = 0; while (i <= 10) { s = s + i; i = i + 1; } putn(s);'
body  factorial     3628800 'int n = 10; int f = 1; while (n > 1) { f = f * n; n = n - 1; } putn(f);'
body  power-of-two  1073741824 'int n = 1; int i = 0; while (i < 30) { n = n * 2; i = i + 1; } putn(n);'
body  fibonacci     55  'int a = 0; int b = 1; int i = 0; while (i < 10) { int t = a + b; a = b; b = t; i = i + 1; } putn(a);'
body  gcd           6   'int a = 48; int b = 18; while (b != 0) { int t = b; b = a % b; a = t; } putn(a);'
body  collatz-27    111 'int n = 27; int c = 0; while (n != 1) { if (n % 2 == 0) n = n / 2; else n = 3 * n + 1; c = c + 1; } putn(c);'
body  big-count     1000000 'int i = 0; while (i < 1000000) i = i + 1; putn(i);'

body  nested        12  'int i = 0; int t = 0; while (i < 3) { int j = 0; while (j < 4) { t = t + 1; j = j + 1; } i = i + 1; } putn(t);'
body  if-inside     20  'int i = 0; int s = 0; while (i < 10) { if (i % 2 == 0) s = s + i; i = i + 1; } putn(s);'
body  return-inside 5   'int i = 0; while (1) { if (i == 5) { putn(i); return 0; } i = i + 1; }'
body  body-scope    "$(printf '0\n1\n4')"   'int i = 0; while (i < 3) { int sq = i * i; putn(sq); i = i + 1; }'
body  loop-then-use 7   'int i = 0; while (i < 7) i = i + 1; int j = i; putn(j);'
body  two-loops     "$(printf '3\n6')"      'int i = 0; while (i < 3) i = i + 1; putn(i); while (i < 6) i = i + 1; putn(i);'

finish