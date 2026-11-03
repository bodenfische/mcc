# local variables
. "$(dirname "$0")/lib.sh"

body  var-init    5  'int x = 5; putn(x);'
body  var-assign  6  'int x = 5; x = x + 1; putn(x);'
body  var-two     7  'int a = 3; int b = 4; putn(a + b);'
body  var-expr    14 'int a = 2; int b = a * 3 + 8; putn(b);'
body  var-swap    21 'int a = 1; int b = 2; int t = a; a = b; b = t; putn(a*10+b);'
body  var-negate  -3 'int x = 3; putn(-x);'
body  var-bracket 20 'int x = 4; putn((x+1)*x);'
body  var-many    10 'int a=1; int b=2; int c=3; int d=4; putn(a+b+c+d);'
body  var-names   3  'int _a1 = 1; int a1_ = 2; putn(_a1 + a1_);'
body  var-twice   "$(printf '9\n10')" 'int x = 9; putn(x); putn(x+1);'
body  var-return  7  'int x = 7; putn(x); return x;'
body  var-late    5  'int x; x = 5; putn(x);'

finish