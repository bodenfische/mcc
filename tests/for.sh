# for loops
. "$(dirname "$0")/lib.sh"

body  count-up       "$(printf '0\n1\n2')"  'for (int i = 0; i < 3; i++) putn(i);'
body  count-down     "$(printf '3\n2\n1')"  'for (int i = 3; i > 0; i--) putn(i);'
body  step-by-three  "$(printf '0\n3\n6\n9')" 'for (int i = 0; i < 10; i += 3) putn(i);'
body  step-doubling  "$(printf '1\n2\n4\n8\n16\n32\n64')" 'for (int i = 1; i < 100; i = i * 2) putn(i);'
body  block-body     "$(printf '0\n0\n1\n10\n2\n20')" 'for (int i = 0; i < 3; i++) { putn(i); putn(i * 10); }'
body  after-loop     "$(printf '0\n1\n5')"  'for (int i = 0; i < 2; i++) putn(i); putn(5);'
body  never-runs     9  'for (int i = 5; i < 3; i++) putn(i); putn(9);'
body  runs-once      7  'for (int i = 0; i < 1; i++) putn(7);'
body  sum-to-ten     55 'int s = 0; for (int i = 1; i <= 10; i++) s += i; putn(s);'
body  big-count      1000000 'int s = 0; for (int i = 0; i < 1000000; i++) s += 1; putn(s);'

# empty parts
body  init-outside   "$(printf '0\n1\n2\n3')" 'int i; for (i = 0; i < 3; i++) putn(i); putn(i);'
body  init-empty     "$(printf '0\n1\n2')"  'int i = 0; for (; i < 3; i++) putn(i);'
body  step-empty     "$(printf '0\n1\n2')"  'for (int i = 0; i < 3;) { putn(i); i++; }'
body  cond-empty     3  'for (int i = 0; ; i++) { if (i == 3) { putn(i); return 0; } }'
body  all-empty      2  'int i = 0; for (;;) { if (i == 2) { putn(i); return 0; } i++; }'

# scope: a variable declared in the brackets lasts as long as the loop
body  scope-ends     "$(printf '0\n1\n7')"  'for (int i = 0; i < 2; i++) { putn(i); } int i = 7; putn(i);'
body  scope-outer    "$(printf '0\n1\n9')"  'int i = 9; for (int i = 0; i < 2; i++) putn(i); putn(i);'
body  scope-body     "$(printf '5\n5')"     'for (int i = 0; i < 2; i++) { int i = 5; putn(i); }'
body  two-loops      "$(printf '0\n1\n5\n6')" 'for (int i = 0; i < 2; i++) putn(i); for (int i = 5; i < 7; i++) putn(i);'

# nesting and mixing
body  nested         12 'int t = 0; for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++) t++; putn(t);'
body  times-table    "$(printf '1\n2\n3\n2\n4\n6\n3\n6\n9')" 'for (int i = 1; i <= 3; i++) { for (int j = 1; j <= 3; j++) putn(i * j); }'
body  factorial      3628800 'int f = 1; for (int n = 10; n > 1; n--) f *= n; putn(f);'
body  fibonacci      55 'int a = 0; int b = 1; for (int i = 0; i < 10; i++) { int t = a + b; a = b; b = t; } putn(a);'
body  if-inside      20 'int s = 0; for (int i = 0; i < 10; i++) if (i % 2 == 0) s += i; putn(s);'
body  logic-cond     "$(printf '0\n1\n2')"  'for (int i = 0; i < 10 && i != 3; i++) putn(i);'
body  primes-to-20   8  'int c = 0; for (int n = 2; n <= 20; n++) { int p = 1; for (int d = 2; d * d <= n; d++) if (n % d == 0) p = 0; c += p; } putn(c);'
body  in-while       6  'int t = 0; int k = 0; while (k < 3) { for (int i = 0; i < 2; i++) t++; k++; } putn(t);'

finish