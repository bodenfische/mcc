# things mcc must refuse
. "$(dirname "$0")/lib.sh"

fails undeclared-use    'putn(y);'
fails undeclared-assign 'y = 1;'
fails redeclared        'int x; int x;'
fails missing-operand   'putn(1 +);'
fails missing-semicolon 'putn(1)'
fails unknown-statement '5;'

finish