# numbers and arithmetic
. "$(dirname "$0")/lib.sh"

body  precedence   14          'putn(2+3*4);'
body  brackets     20          'putn((2+3)*4);'
body  divide       14          'putn(100/7);'
body  modulo       2           'putn(100%7);'
body  negate       7           'putn(-(3-10));'
body  left-assoc   5           'putn(10-3-2);'
body  div-then-mul 6           'putn(7/2*2);'
body  mixed        5           'putn(1+2*3-4/2);'
body  big          1000000     'putn(1000*1000);'
body  zero         0           'putn(0);'
body  negative     -5          'putn(-5);'
body  int-max      2147483647  'putn(2147483647);'
body  int-min      -2147483648 'putn(-2147483647-1);'
body  neg-divide   -3          'putn(-7/2);'
body  neg-modulo   -1          'putn(-7%2);'

finish