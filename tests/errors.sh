# things mcc must refuse
. "$(dirname "$0")/lib.sh"

fails undeclared-use    'putn(y);'
fails undeclared-assign 'y = 1;'
fails redeclared        'int x; int x;'
fails missing-operand   'putn(1 +);'
fails missing-semicolon 'putn(1)'
fails unknown-statement '5;'
fails compare-no-right  'putn(1 ==);'
fails compare-no-left   'putn(< 1);'

fails if-no-brackets    'if 1 putn(1);'
fails if-unclosed       'if (1 putn(1);'
fails else-alone        'if (1) else putn(1);'
fails block-unclosed    'if (1) { putn(1);'
fails block-redeclare   'if (1) { int x; int x; }'
fails block-var-escapes 'if (1) { int y = 1; } putn(y);'
fails while-no-brackets 'while 1 putn(1);'
fails while-unclosed     'while (1 putn(1);'
fails while-no-condition 'while () putn(1);'
fails unterminated-comment 'putn(1); /* never ends'

finish