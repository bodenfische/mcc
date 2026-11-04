# if / else, { } blocks and block scope
. "$(dirname "$0")/lib.sh"

body  if-true        1  'if (1) putn(1);'
body  if-false       "" 'if (0) putn(1);'
body  if-else-true   1  'if (1) putn(1); else putn(2);'
body  if-else-false  2  'if (0) putn(1); else putn(2);'
body  cond-compare   1  'int x = 5; if (x > 3) putn(1); else putn(0);'
body  cond-nonzero   1  'if (7) putn(1);'
body  cond-negative  1  'if (-1) putn(1);'
body  cond-variable  1  'int x = 2; if (x) putn(1); else putn(0);'
body  cond-zero-var  0  'int x = 0; if (x) putn(1); else putn(0);'
body  after-if       2  'if (0) putn(1); putn(2);'
body  assign-branch  10 'int x = 1; if (x == 1) x = 10; else x = 20; putn(x);'

body  block          "$(printf '1\n2')"    'if (1) { putn(1); putn(2); }'
body  block-skipped  3  'if (0) { putn(1); putn(2); } putn(3);'
body  else-block     "$(printf '2\n3')"    'if (0) { putn(1); } else { putn(2); putn(3); }'
body  empty-block    1  'if (1) { } putn(1);'
body  plain-block    "$(printf '1\n2')"    '{ putn(1); } putn(2);'

body  nested         2  'int x = 5; if (x > 0) { if (x > 10) putn(1); else putn(2); } else putn(3);'
body  dangling-else  2  'if (1) if (0) putn(1); else putn(2);'
body  else-if-neg    -1 'int x = -5; if (x < 0) putn(-1); else if (x == 0) putn(0); else putn(1);'
body  else-if-zero   0  'int x = 0; if (x < 0) putn(-1); else if (x == 0) putn(0); else putn(1);'
body  else-if-pos    1  'int x = 5; if (x < 0) putn(-1); else if (x == 0) putn(0); else putn(1);'
body  return-in-if   1  'int x = 3; if (x == 3) { putn(1); return 0; } putn(2);'
body  max            9  'int a = 4; int b = 9; int m; if (a > b) m = a; else m = b; putn(m);'
body  one-after-other "$(printf '1\n3')" 'if (1) putn(1); else putn(2); if (0) putn(2); else putn(3);'

# variables declared inside a block disappear at the closing brace
body  scope-inner    "$(printf '5\n7')"    'int x = 1; if (x) { int y = 5; putn(y); } int y = 7; putn(y);'
body  scope-shadow   "$(printf '2\n1')"    'int x = 1; if (1) { int x = 2; putn(x); } putn(x);'
body  scope-outer    6  'int x = 1; if (1) { x = 6; } putn(x);'
body  scope-reuse    "$(printf '1\n2\n3')" 'int a = 1; { int b = 2; putn(a); putn(b); } { int c = 3; putn(c); }'
body  scope-nested   "$(printf '1\n2\n3')" '{ int a = 1; { int b = 2; { int c = 3; putn(a); putn(b); putn(c); } } }'

finish