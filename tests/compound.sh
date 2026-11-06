# += -= *= /= %=
. "$(dirname "$0")/lib.sh"

body  plus-eq        8   'int x = 5; x += 3; putn(x);'
body  plus-eq-maths  12  'int x = 5; x += 2 * 3 + 1; putn(x);'

body  minus-eq       2   'int x = 5; x -= 3; putn(x);'
body  minus-eq-neg   7   'int x = 5; x -= -2; putn(x);'
body  minus-eq-self  0   'int x = 5; x -= x; putn(x);'
body  minus-eq-sum   8   'int x = 10; x -= 1 + 1; putn(x);'
body  minus-eq-maths 13  'int x = 20; x -= 2 * 3 + 1; putn(x);'
body  minus-eq-cmp   4   'int x = 5; x -= 3 > 2; putn(x);'
body  minus-eq-below -4  'int x = 1; x -= 5; putn(x);'

body  times-eq       42  'int x = 6; x *= 7; putn(x);'
body  times-eq-neg   -6  'int x = 6; x *= -1; putn(x);'
body  times-eq-zero  0   'int x = 6; x *= 0; putn(x);'
body  times-eq-self  36  'int x = 6; x *= x; putn(x);'
body  times-eq-sum   30  'int x = 6; x *= 2 + 3; putn(x);'

body  div-eq         14  'int x = 100; x /= 7; putn(x);'
body  div-eq-neg     -14 'int x = 100; x /= -7; putn(x);'
body  div-eq-negx    -14 'int x = -100; x /= 7; putn(x);'
body  div-eq-self    1   'int x = 9; x /= x; putn(x);'
body  div-eq-sum     20  'int x = 100; x /= 2 + 3; putn(x);'

body  mod-eq         2   'int x = 100; x %= 7; putn(x);'
body  mod-eq-negx    -2  'int x = -100; x %= 7; putn(x);'
body  mod-eq-sum     0   'int x = 100; x %= 2 + 3; putn(x);'
body  mod-eq-times   16  'int x = 100; x %= 7 * 3; putn(x);'

body  chain          2   'int x = 10; x += 5; x -= 3; x *= 2; x /= 4; x %= 4; putn(x);'
body  no-spaces      1   'int x = 8; x/=2; x*=3; x-=1; x%=5; putn(x);'
body  two-vars       "$(printf '21\n2\n3')" 'int a = 10; int b = 3; a -= b; a *= b; putn(a); int c = 17; int d = 5; int e = c; c %= d; e /= d; putn(c); putn(e);'

# in loops
body  factorial      3628800 'int n = 10; int f = 1; while (n > 1) { f *= n; n--; } putn(f);'
body  digit-sum      15  'int n = 12345; int s = 0; while (n) { s += n % 10; n /= 10; } putn(s);'
body  collatz-27     111 'int n = 27; int c = 0; while (n != 1) { if (n % 2) { n *= 3; n++; } else n /= 2; c++; } putn(c);'
body  power-of-two   1024 'int r = 1; int i = 0; while (i < 10) { r *= 2; i++; } putn(r);'
body  step-below-zero -2 'int n = 10; while (n > 0) { n -= 3; } putn(n);'

finish