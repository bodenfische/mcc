# hex numbers and character literals
. "$(dirname "$0")/lib.sh"

body  hex-small      16         'putn(0x10);'
body  hex-ff         255        'putn(0xff);'
body  hex-upper-x    255        'putn(0XFF);'
body  hex-mixed-case 43981      'putn(0xAbCd);'
body  hex-zero       0          'putn(0x0);'
body  hex-leading-0  255        'putn(0x00ff);'
body  hex-int-max    2147483647 'putn(0x7fffffff);'
body  hex-elf-magic  1179403647 'putn(0x464c457f);'
body  hex-load-addr  4194304    'putn(0x400000);'
body  hex-maths      4112       'putn(0x1000 + 0x10);'
body  hex-times      256        'putn(0x10 * 0x10);'
body  hex-negate     -16        'putn(-0x10);'
body  hex-below-zero -16        'putn(0x10 - 0x20);'
body  hex-compare    1          'putn(0x10 == 16);'
body  hex-variable   32         'int x = 0x20; putn(x);'
body  hex-step       "$(printf '0\n16\n32')" 'for (int i = 0; i < 48; i += 0x10) putn(i);'

body  char-a         97   "putn('a');"
body  char-upper     65   "putn('A');"
body  char-digit     48   "putn('0');"
body  char-space     32   "putn(' ');"
body  char-tilde     126  "putn('~');"
body  char-newline   10   "putn('\n');"
body  char-tab       9    "putn('\t');"
body  char-return    13   "putn('\r');"
body  char-nul       0    "putn('\0');"
body  char-backslash 92   "putn('\\\\');"
body  char-quote     39   "putn('\\'');"
body  char-dquote    34   "putn('\"');"
body  char-brackets  40   "putn('(');"
body  char-newline-is-10 1 "putn('\n' == 10);"
body  char-plus      98   "putn('a' + 1);"
body  char-minus     25   "putn('z' - 'a');"
body  char-digit-val 7    "putn('7' - '0');"
body  char-compare   1    "putn('a' < 'b');"
body  char-variable  120  "int c = 'x'; putn(c);"
body  char-spaced    97   "putn( 'a' );"
body  char-in-if     1    "int c = 'q'; if (c == 'q') putn(1); else putn(0);"
body  char-loop      "$(printf '97\n98\n99\n100\n101')" "for (int c = 'a'; c <= 'e'; c++) putn(c);"

# escapes in strings go through the same code
body  string-tab     "$(printf 'tab:\there')" 'puts("tab:\there");'
body  string-quote   'q"q'  'puts("q\"q");'
body  string-slash   'a\b'  'puts("a\\b");'

finish