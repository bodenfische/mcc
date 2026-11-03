# hello world and strings
. "$(dirname "$0")/lib.sh"

check hello   "Hello, world!" examples/hello.c
body  strings "$(printf 'a\n1')" 'puts("a"); putn(1);'

finish