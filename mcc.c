/* mcc - micro C compiler for Linux x86-64. No libc.
 * Build:  gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
 * Use:    ./mcc in.c [out]    (out defaults to a.out)
 * Reads:  int fact(int n) { if (n < 2) return 1; return n * fact(n - 1); }
 *          int main() { putn(fact(5)); return 0; }
 */
typedef unsigned long u64;
typedef unsigned int u32;
typedef unsigned char u8;

static long sys(long n, long a, long b, long c) {
    long r;
    __asm__ volatile("syscall" : "=a"(r) : "a"(n), "D"(a), "S"(b), "d"(c)
                     : "rcx", "r11", "memory");
    return r;
}

static char src[65536];
static u8 code[4096], data[4096], out[16384];
static int nc, nd, no, np;
static u32 patch_at[64], patch_str[64];
static u32 call_at[64];
static int ncall;

/* Variables are found by their position in this table: vname holds the names,
 * voff where each one sits relative to rbp, and nvar says how many there are.
 * Parameters come first. The caller pushed them, so they're above rbp
 * ([rbp+16] and up, 8 bytes each). Locals are 4 bytes each below it: the first at
 * [rbp-4], the second at [rbp-8], and so on. The table starts over for each function.
 *
 * A { } block gets its own scope: variables declared inside it vanish at the
 * closing brace, and their stack slots get reused. scope is the first variable
 * that belongs to the current block, nparams how many of the variables are
 * parameters, and maxvar the most locals alive at once, which decides how much
 * stack space the function needs. */
static char vname[64][32];
static int voff[64];
static int nvar, nparams, scope, maxvar;

/* Functions: name, parameter count, whether it returns void, and where its code
 * starts (-1 until it's defined). Calls are recorded as they're generated and
 * pointed at the right address once everything is defined. Entry 0 is always main. */
static char fname[32][32];
static int fparams[32], fvoid[32], faddr[32];
static int nfn;
static u32 fcall_at[256];
static int fcall_fn[256], nfcall;
static int curvoid;                     /* is the function being compiled void? */
static char name[32];                   /* the name ident() just read */
static char *p;

static long slen(char *s) { long n = 0; while (s[n]) n++; return n; }
static void err(char *s) { sys(1, 2, (long)s, slen(s)); }
static void die(char *m, char *x) {
    err("mcc: ");
    if (p) {                            /* once the source is loaded, say which line the problem is on */
        int line = 1;
        for (char *q = src; q < p; q++) if (*q == '\n') line++;
        char digits[12];
        int i = 11;
        digits[i] = 0;
        do { digits[--i] = '0' + line % 10; line /= 10; } while (line);
        err("line "); err(digits + i); err(": ");
    }
    err(m); if (x) { err(" '"); err(x); err("'"); } err("\n");
    sys(60, 1, 0, 0);
}

static void emit(int b) { code[nc++] = b; }
static void emit32(u32 v) { for (int i = 0; i < 4; i++) emit(v >> (8 * i)); }
static void o(u64 v, int n) { for (int i = 0; i < n; i++) out[no++] = v >> (8 * i); }

/* Skip spaces, newlines and comments (// to the end of the line, and block
 * comments). A comment counts as whitespace, so nothing else needs to know about them. */
static void ws(void) {
    for (;;) {
        if (*p == ' ' || *p == '\n' || *p == '\t' || *p == '\r') p++;
        else if (p[0] == '/' && p[1] == '/') { while (*p && *p != '\n') p++; }
        else if (p[0] == '/' && p[1] == '*') {
            char *start = p;
            p += 2;
            while (*p && !(p[0] == '*' && p[1] == '/')) p++;
            if (!*p) { p = start; die("unterminated comment", 0); }   /* point at where it began */
            p += 2;
        }
        else return;
    }
}
static int isw(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}
static int eat(char *s) {
    ws();
    int n = 0;
    while (s[n]) { if (p[n] != s[n]) return 0; n++; }
    if (isw(s[0]) && isw(p[n])) return 0;
    p += n;
    return 1;
}
static void expect(char *s) { if (!eat(s)) die("expected", s); }

/* Read a name from the source into name[]. */
static void ident(void) {
    ws();
    int n = 0;
    if (!isw(*p) || (*p >= '0' && *p <= '9')) die("expected a name", 0);
    while (isw(*p)) {
        if (n == 31) die("name too long", 0);
        name[n++] = *p++;
    }
    name[n] = 0;
}

/* Look name[] up in the variable table, newest first so an inner variable hides an
 * outer one of the same name. Variables before number lo are ignored. Gives the
 * variable's number, or -1 if it isn't there. */
static int find(int lo) {
    for (int i = nvar - 1; i >= lo; i--) {
        int j = 0;
        while (vname[i][j] == name[j] && name[j]) j++;
        if (vname[i][j] == name[j]) return i;
    }
    return -1;
}

/* Same, but a missing variable is an error. */
static int lookup(void) {
    int i = find(0);
    if (i < 0) die("undeclared", name);
    return i;
}

/* Variable number i sits at [rbp + voff[i]]. These copy it into eax and back. */
static void load(int i)  { emit(0x8b); emit(0x85); emit32(voff[i]); }       /* eax = the variable */
static void store(int i) { emit(0x89); emit(0x85); emit32(voff[i]); }       /* the variable = eax */

/* ++ and -- change the variable in memory directly, leaving eax alone. */
static void add_const(int i, int amount) {                                   /* the variable += amount (1 or -1) */
    emit(0x83); emit(0x85); emit32(voff[i]); emit(amount & 0xff);
}

/* The compound assignments: variable = variable op eax, where op is one of + - * / % */
static void modify(int i, int op) {
    int off = voff[i];
    if (op == '+') { emit(0x01); emit(0x85); emit32(off); }                  /* add [variable], eax */
    else if (op == '-') { emit(0x29); emit(0x85); emit32(off); }             /* sub [variable], eax */
    else if (op == '*') {
        emit(0x0f); emit(0xaf); emit(0x85); emit32(off);                     /* eax = eax * variable */
        store(i);
    } else {                                                                 /* / and %: the variable is the dividend */
        emit(0x89); emit(0xc1);                                              /* ecx = eax, the divisor */
        load(i);
        emit(0x99); emit(0xf7); emit(0xf9);                                  /* cdq, idiv ecx */
        if (op == '%') { emit(0x89); emit(0xd0); }                           /* remainder: eax = edx */
        store(i);
    }
}

/* Leave the current function, with the result in eax. */
static void leave(void) {
    emit(0x48); emit(0x89); emit(0xec);                 /* rsp = rbp, dropping the locals */
    emit(0x5d);                                         /* restore the caller's rbp */
    emit(0xc3);                                         /* return */
}

/* Machine code for putn: prints the number in eax, then a newline.
 * It is added to the end of the program once, and every putn(...) calls it. */
static u8 putn_code[] = {
    0x48,0x83,0xec,0x10,             /* make a 16 byte buffer on the stack */
    0x48,0x8d,0x7c,0x24,0x0f,        /* rdi = last byte of the buffer */
    0xc6,0x07,0x0a,                  /* put a newline there */
    0x31,0xf6,                       /* esi = 0 (will be 1 if negative) */
    0x85,0xc0,                       /* if eax is negative: */
    0x79,0x04,
    0xf7,0xd8,                       /*   eax = -eax */
    0xff,0xc6,                       /*   esi = 1 */
    0xb9,0x0a,0x00,0x00,0x00,        /* ecx = 10 */
    /* loop: one digit each time, working from the right */
    0x31,0xd2,                       /* edx = 0 */
    0xf7,0xf1,                       /* eax = eax / 10, edx = remainder */
    0x80,0xc2,0x30,                  /* dl = dl + '0' */
    0x48,0xff,0xcf,                  /* rdi = rdi - 1 */
    0x88,0x17,                       /* store the digit */
    0x85,0xc0,                       /* go round again until eax is 0 */
    0x75,0xf0,
    0x85,0xf6,                       /* if it was negative: */
    0x74,0x06,
    0x48,0xff,0xcf,                  /*   rdi = rdi - 1 */
    0xc6,0x07,0x2d,                  /*   store '-' */
    0x48,0x8d,0x54,0x24,0x10,        /* rdx = end of the buffer */
    0x48,0x29,0xfa,                  /* rdx = rdx - rdi (the length) */
    0x48,0x89,0xfe,                  /* rsi = rdi (the start) */
    0xbf,0x01,0x00,0x00,0x00,        /* edi = 1 (stdout) */
    0xb8,0x01,0x00,0x00,0x00,        /* eax = 1 (write) */
    0x0f,0x05,                       /* syscall */
    0x48,0x83,0xc4,0x10,             /* give the buffer back */
    0xc3,                            /* return */
};

/* Expressions. Every function leaves its answer in eax.
 * For "a op b": work out a, push it, work out b, move b to ecx, pop a, do the op. */
static void expr(void);

/* The character a backslash escape stands for, in a string or a 'c' literal.
 * Called with p just past the backslash. \\ \' and \" are themselves. */
static int escape(void) {
    if (!*p) die("bad escape", 0);
    char c = *p++;
    if (c == 'n') return 10;
    if (c == 't') return 9;
    if (c == 'r') return 13;
    if (c == '0') return 0;
    return c;
}

/* The value of a hex digit, or -1 if it isn't one. */
static int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int same(char *a, char *b) {
    int j = 0;
    while (a[j] == b[j] && a[j]) j++;
    return a[j] == b[j];
}

/* Which function has the name in name[]? Gives its number, or -1. */
static int find_fn(void) {
    for (int i = 0; i < nfn; i++) if (same(fname[i], name)) return i;
    return -1;
}

/* Code for a call to function f, called just after its "(". The arguments are
 * worked out left to right and pushed, so the last one ends up nearest the top of
 * the stack. The result comes back in eax. The caller drops the arguments again. */
static void call(int f) {
    int n = 0;
    if (!eat(")")) {
        do {
            if (n == 12) die("too many arguments", 0);
            expr(); emit(0x50); n++;
        } while (eat(","));
        expect(")");
    }
    if (n != fparams[f]) die("wrong number of arguments to", fname[f]);
    if (nfcall == 256) die("too many calls", 0);
    emit(0xe8); fcall_at[nfcall] = nc; fcall_fn[nfcall++] = f; emit32(0);   /* address filled in once all functions are defined */
    if (n) { emit(0x48); emit(0x83); emit(0xc4); emit(8 * n); }              /* rsp += 8 * n */
}

static void factor(void) {
    ws();
    if (eat("(")) { expr(); expect(")"); }
    else if (eat("++")) { ident(); int i = lookup(); add_const(i, 1); load(i); }    /* ++x: the new value */
    else if (eat("--")) { ident(); int i = lookup(); add_const(i, -1); load(i); }
    else if (eat("-")) { factor(); emit(0xf7); emit(0xd8); }       /* neg eax (after -- so "--x" isn't read as two minuses) */
    else if (eat("!")) {                                            /* 1 if it was zero, otherwise 0 */
        factor();
        emit(0x85); emit(0xc0);                                     /* is eax zero? */
        emit(0x0f); emit(0x94); emit(0xc0);                         /* al = 1 if it was, otherwise 0 */
        emit(0x0f); emit(0xb6); emit(0xc0);                         /* eax = al */
    }
    else if (*p >= '0' && *p <= '9') {
        u32 v = 0;
        if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {          /* hex, like 0x1F */
            p += 2;
            if (hexval(*p) < 0) die("expected hex digits", 0);
            while (hexval(*p) >= 0) v = v * 16 + hexval(*p++);
        } else while (*p >= '0' && *p <= '9') v = v * 10 + (*p++ - '0');
        emit(0xb8); emit32(v);                                      /* eax = number */
    } else if (*p == '\'') {                                        /* 'a' is just the number 97 */
        p++;
        if (*p == '\'' || *p == '\n' || !*p) die("bad character literal", 0);
        int c = *p++;
        if (c == '\\') c = escape();
        if (*p != '\'') die("bad character literal", 0);
        p++;
        emit(0xb8); emit32(c);                                      /* eax = the character's value */
    } else if (isw(*p)) {
        ident();
        if (eat("(")) {                                             /* a call, like f(a, b) */
            int f = find_fn();
            if (f < 0) die("undeclared function", name);
            if (fvoid[f]) die("void function used as a value", name);
            call(f);
        } else {                                                    /* a variable, maybe with x++ or x-- */
            int i = lookup();
            load(i);                                                /* eax = the old value, which x++ gives back */
            if (eat("++")) add_const(i, 1); else if (eat("--")) add_const(i, -1);
        }
    }
    else die("expected expression", 0);
}

static void term(void) {
    factor();
    for (;;) {
        int op;
        if (eat("*")) op = 0; else if (eat("/")) op = 1; else if (eat("%")) op = 2; else return;
        emit(0x50); factor(); emit(0x89); emit(0xc1); emit(0x58);   /* push, right side, ecx = eax, pop */
        if (op == 0) { emit(0x0f); emit(0xaf); emit(0xc1); }        /* imul eax, ecx */
        else {
            emit(0x99); emit(0xf7); emit(0xf9);                     /* cdq, idiv ecx */
            if (op == 2) { emit(0x89); emit(0xd0); }                /* remainder: eax = edx */
        }
    }
}

static void sum(void) {                 /* + and - */
    term();
    for (;;) {
        int sub;
        if (eat("+")) sub = 0; else if (eat("-")) sub = 1; else return;
        emit(0x50); term(); emit(0x89); emit(0xc1); emit(0x58);     /* push, right side, ecx = eax, pop */
        if (sub) { emit(0x29); emit(0xc8); }                        /* sub eax, ecx */
        else { emit(0x01); emit(0xc8); }                            /* add eax, ecx */
    }
}

/* Comparisons give 1 for true and 0 for false, like C. They work the same way as
 * + and -, except for the last step: compare eax with ecx, then set eax to 1 or 0
 * depending on the result. setcc picks which test to use (equal, less than...). */
static void compare(int setcc) {
    emit(0x39); emit(0xc8);             /* compare eax with ecx */
    emit(0x0f); emit(setcc); emit(0xc0);/* al = 1 if the test passed, otherwise 0 */
    emit(0x0f); emit(0xb6); emit(0xc0); /* eax = al, so the rest of eax is 0 */
}

/* < > <= >= bind tighter than == and !=, same as in C. The two character ones
 * are checked first, otherwise "<" would grab the front of "<=". */
static void relation(void) {
    sum();
    for (;;) {
        int cc;
        if (eat("<=")) cc = 0x9e; else if (eat(">=")) cc = 0x9d;
        else if (eat("<")) cc = 0x9c; else if (eat(">")) cc = 0x9f; else return;
        emit(0x50); sum(); emit(0x89); emit(0xc1); emit(0x58);      /* push, right side, ecx = eax, pop */
        compare(cc);
    }
}

static void equality(void) {            /* == != */
    relation();
    for (;;) {
        int cc;
        if (eat("==")) cc = 0x94; else if (eat("!=")) cc = 0x95; else return;
        emit(0x50); relation(); emit(0x89); emit(0xc1); emit(0x58);
        compare(cc);
    }
}

/* Jumps. How far to jump isn't known until the code being skipped has been
 * written, so these leave the distance blank and hand back where it is. Once the
 * code to skip is done, here() goes back and fills the distance in. */
static int jump_if_zero(void) { emit(0x0f); emit(0x84); emit32(0); return nc - 4; }
static int jump_if_nonzero(void) { emit(0x0f); emit(0x85); emit32(0); return nc - 4; }
static int jump(void) { emit(0xe9); emit32(0); return nc - 4; }
static void jump_back(int target) {     /* a jump to code that's already been written */
    emit(0xe9);
    emit32(target - (nc + 4));
}
static void here(int at) {
    u32 rel = nc - (at + 4);            /* distances count from the end of the jump instruction */
    for (int k = 0; k < 4; k++) code[at + k] = rel >> (8 * k);
}

/* && and || short-circuit, so they skip the push/pop recipe and use jumps: each
 * operand is tested, and one that settles the result jumps to the end. The
 * result is normalised to 1 or 0. A chain keeps its pending jumps in a list. */
static void logical_and(void) {
    equality();
    if (!eat("&&")) return;
    int miss[33], n = 0;
    do {
        emit(0x85); emit(0xc0);                         /* is eax zero? */
        if (n == 32) die("too many && in a row", 0);
        miss[n++] = jump_if_zero();                     /* yes: the whole thing is false */
        equality();
    } while (eat("&&"));
    emit(0x85); emit(0xc0);
    miss[n++] = jump_if_zero();
    emit(0xb8); emit32(1);                              /* every part was true: eax = 1 */
    int done = jump();
    for (int i = 0; i < n; i++) here(miss[i]);
    emit(0x31); emit(0xc0);                             /* eax = 0 */
    here(done);
}

/* == and != are not the loosest any more: && and || are, so this is the top,
 * a whole expression. || is looser than &&, as in C. */
static void expr(void) {
    logical_and();
    if (!eat("||")) return;
    int hit[33], n = 0;
    do {
        emit(0x85); emit(0xc0);                         /* is eax zero? */
        if (n == 32) die("too many || in a row", 0);
        hit[n++] = jump_if_nonzero();                   /* no: the whole thing is true */
        logical_and();
    } while (eat("||"));
    emit(0x85); emit(0xc0);
    hit[n++] = jump_if_nonzero();
    emit(0x31); emit(0xc0);                             /* every part was false: eax = 0 */
    int done = jump();
    for (int i = 0; i < n; i++) here(hit[i]);
    emit(0xb8); emit32(1);                              /* eax = 1 */
    here(done);
}

/* The two kinds of statement that a for loop can have in its brackets, so they're
 * parsed without the closing ";". */

/* x  or  x = <expression>  (after "int"). Reserves a slot for the name. A bare
 * "int x;" makes no code, so the slot keeps whatever was there, as in C. A name can
 * only clash with one from the same block, so an inner block may reuse an outer name. */
static void declare(void) {
    ident();
    if (find(scope) >= 0) die("already declared", name);
    if (nvar == 64) die("too many variables", 0);
    int i = nvar++;
    if (nvar - nparams > maxvar) maxvar = nvar - nparams;
    for (int j = 0; j < 32; j++) vname[i][j] = name[j];
    voff[i] = -4 * (i - nparams + 1);                   /* locals sit below rbp, after the parameters in the table */
    if (eat("=")) { expr(); store(i); }
}

/* x = e   x += e   x -= e   x *= e   x /= e   x %= e   x++   x--   ++x   --x
 * Assignment is a statement only, not an expression. */
static void simple(void) {
    ws();
    if (eat("++")) { ident(); add_const(lookup(), 1); }
    else if (eat("--")) { ident(); add_const(lookup(), -1); }
    else {
        if (!isw(*p)) die("unsupported statement", 0);
        ident();
        if (eat("(")) {                                 /* a call used as a statement; any result is dropped */
            int f = find_fn();
            if (f < 0) die("undeclared function", name);
            call(f);
            return;
        }
        int i = lookup();
        if (eat("++")) add_const(i, 1);
        else if (eat("--")) add_const(i, -1);
        else {
            int op = 0;
            if (eat("+=")) op = '+'; else if (eat("-=")) op = '-'; else if (eat("*=")) op = '*';
            else if (eat("/=")) op = '/'; else if (eat("%=")) op = '%';
            if (op) { expr(); modify(i, op); }
            else { expect("="); expr(); store(i); }
        }
    }
}

static void stmt(void) {
    if (eat("puts")) {
        expect("("); expect("\"");
        int start = nd;
        for (;;) {
            char c = *p++;
            if (!c) die("unterminated string", 0);
            if (c == '"') break;
            if (c == '\\') c = escape();
            data[nd++] = c;
        }
        data[nd++] = '\n';
        expect(")"); expect(";");
        emit(0xb8); emit32(1);          /* eax = 1 (write) */
        emit(0xbf); emit32(1);          /* edi = 1 (stdout) */
        emit(0xbe); patch_at[np] = nc; patch_str[np++] = start; emit32(0); /* esi = text address, filled in later */
        emit(0xba); emit32(nd - start); /* edx = length */
        emit(0x0f); emit(0x05);         /* syscall */
    } else if (eat("putn")) {
        expect("("); expr(); expect(")"); expect(";");
        if (ncall == 64) die("too many putn calls", 0);
        emit(0xe8); call_at[ncall++] = nc; emit32(0);   /* call putn, address filled in later */
    } else if (eat("return")) {
        /* return expression;  or just  return;  in a void function */
        if (!curvoid) expr();
        expect(";");
        leave();
    } else if (eat("{")) {
        /* { ... } a block: any number of statements. Variables declared inside
         * are forgotten at the closing brace. */
        int saved = nvar, outer = scope;
        scope = nvar;
        while (!eat("}")) stmt();
        nvar = saved; scope = outer;
    } else if (eat("if")) {
        /* if (condition) statement   or   if (condition) statement else statement
         * Zero counts as false and anything else as true. The code tests eax and
         * jumps over the "if" part when it's zero. With an "else", the "if" part
         * ends with a second jump that skips over the "else" part. */
        expect("("); expr(); expect(")");
        emit(0x85); emit(0xc0);                         /* is eax zero? */
        int skip = jump_if_zero();
        stmt();
        if (eat("else")) {
            int end = jump();
            here(skip);                                 /* a false condition lands here, on the else part */
            stmt();
            here(end);
        } else here(skip);
    } else if (eat("while")) {
        /* while (condition) statement
         * Same as an "if", except the end of the body jumps back up to the
         * condition, so it gets tested again. When the condition finally comes
         * out as zero, the jump at the top skips past the whole loop. */
        int top = nc;
        expect("("); expr(); expect(")");
        emit(0x85); emit(0xc0);                         /* is eax zero? */
        int skip = jump_if_zero();
        stmt();
        jump_back(top);
        here(skip);
    } else if (eat("for")) {
        /* for (init; condition; step) statement
         * Any of the three parts can be left empty, and an empty condition is
         * always true. A variable declared in init lasts as long as the loop.
         * The step is written before the body in the source but has to run after
         * it, so the layout is:
         *     init
         *     top:   condition, jump to end if false
         *            jump to body
         *     step:  step, jump to top
         *     body:  body, jump to step
         *     end: */
        int saved = nvar, outer = scope;
        scope = nvar;
        expect("(");
        if (!eat(";")) {
            if (eat("int")) declare(); else simple();
            expect(";");
        }
        int top = nc, skip = -1;
        if (!eat(";")) {
            expr(); expect(";");
            emit(0x85); emit(0xc0);                     /* is eax zero? */
            skip = jump_if_zero();
        }
        int to_body = jump();
        int step = nc;
        if (!eat(")")) { simple(); expect(")"); }
        jump_back(top);
        here(to_body);
        stmt();
        jump_back(step);
        if (skip >= 0) here(skip);
        nvar = saved; scope = outer;
    } else if (eat("int")) {
        declare();
        expect(";");
    } else {
        simple();
        expect(";");
    }
}

static char pname[12][32];              /* parameter names, empty if a prototype leaves them out */

/* One function at the top level: either a definition, or a prototype ending in ";"
 * (which lets earlier code call a function that's defined further down). */
static void function(void) {
    int isvoid = 0;
    if (eat("int")) isvoid = 0; else if (eat("void")) isvoid = 1; else die("expected a function", 0);
    ident();
    char fn[32];
    for (int j = 0; j < 32; j++) fn[j] = name[j];
    expect("(");

    int n = 0;                                          /* the parameters: (), (void), or ints with optional names */
    if (eat("void")) expect(")");
    else if (!eat(")")) {
        do {
            if (n == 12) die("too many parameters", 0);
            expect("int");
            ws();
            if (isw(*p)) { ident(); for (int j = 0; j < 32; j++) pname[n][j] = name[j]; }
            else pname[n][0] = 0;
            n++;
        } while (eat(","));
        expect(")");
    }

    int f = -1;                                         /* a prototype and the definition must agree */
    for (int i = 0; i < nfn; i++) if (same(fname[i], fn)) f = i;
    if (f >= 0) {
        if (fparams[f] != n || fvoid[f] != isvoid) die("conflicting declaration of", fn);
    } else {
        if (nfn == 32) die("too many functions", 0);
        f = nfn++;
        for (int j = 0; j < 32; j++) fname[f][j] = fn[j];
        fparams[f] = n; fvoid[f] = isvoid; faddr[f] = -1;
    }
    if (eat(";")) return;

    expect("{");
    if (faddr[f] >= 0) die("already defined", fn);
    faddr[f] = nc;

    /* Start of the function: the parameters become its first variables. Then room
     * is made on the stack for the locals. How many there are isn't known until
     * the whole function has been read, so the amount is left blank for now. */
    nvar = 0; scope = 0; maxvar = 0; nparams = n; curvoid = isvoid;
    for (int k = 0; k < n; k++) {
        if (!pname[k][0]) die("parameter needs a name", 0);
        for (int j = 0; j < 32; j++) name[j] = pname[k][j];
        if (find(0) >= 0) die("already declared", name);
        for (int j = 0; j < 32; j++) vname[nvar][j] = name[j];
        voff[nvar++] = 16 + 8 * (n - 1 - k);            /* pushed first means furthest from rbp */
    }
    emit(0x55);                                         /* save rbp */
    emit(0x48); emit(0x89); emit(0xe5);                 /* rbp = rsp, so variables can be found relative to rbp */
    emit(0x48); emit(0x81); emit(0xec);                 /* move rsp down to make room for the locals */
    int frame_at = nc; emit32(0);                       /* the amount, filled in below */
    while (!eat("}")) stmt();
    emit(0x31); emit(0xc0);                             /* running off the end returns 0, which is what main needs */
    leave();
    u32 frame = (maxvar * 4 + 15) & ~15;                /* 4 bytes each, rounded up to a multiple of 16 */
    for (int k = 0; k < 4; k++) code[frame_at + k] = frame >> (8 * k);
}

static int qmain(int argc, char **argv) {
    if (argc < 2) die("usage: mcc in.c [out]", 0);
    long fd = sys(2, (long)argv[1], 0, 0);
    if (fd < 0) die("cannot open", argv[1]);
    long n = sys(0, fd, (long)src, sizeof src - 1);
    if (n < 0) die("read failed", 0);
    src[n] = 0;
    p = src;

    /* The program starts with a few instructions that call main and then exit with
     * whatever it returned, so main is an ordinary function. main is function 0. */
    for (int j = 0; "main"[j]; j++) fname[0][j] = "main"[j];
    nfn = 1; faddr[0] = -1;
    emit(0xe8); fcall_at[nfcall] = nc; fcall_fn[nfcall++] = 0; emit32(0);   /* call main */
    emit(0x89); emit(0xc7);                             /* edi = eax, the exit code */
    emit(0xb8); emit32(60);                             /* eax = 60 (exit) */
    emit(0x0f); emit(0x05);                             /* syscall */

    ws();
    while (*p) { function(); ws(); }
    if (faddr[0] < 0) { p = 0; die("no main function", 0); }

    /* Every call was written with a blank address, because the function might not
     * have existed yet. Now they all do, so point each call at its function. */
    for (int i = 0; i < nfcall; i++) {
        int f = fcall_fn[i];
        if (faddr[f] < 0) { p = 0; die("declared but never defined", fname[f]); }
        u32 rel = faddr[f] - (fcall_at[i] + 4);
        for (int k = 0; k < 4; k++) code[fcall_at[i] + k] = rel >> (8 * k);
    }

    if (ncall) {                        /* add putn after the program, then fix the calls */
        int at = nc;
        for (int i = 0; i < (int)sizeof putn_code; i++) emit(putn_code[i]);
        for (int i = 0; i < ncall; i++) {
            u32 rel = at - (call_at[i] + 4);
            for (int k = 0; k < 4; k++) code[call_at[i] + k] = rel >> (8 * k);
        }
    }

    u64 base = 0x400000, hdr = 64 + 56;
    u64 dataaddr = base + hdr + nc;
    for (int i = 0; i < np; i++) {
        u32 v = dataaddr + patch_str[i];
        for (int k = 0; k < 4; k++) code[patch_at[i] + k] = v >> (8 * k);
    }
    u64 total = hdr + nc + nd;

    /* ELF header */
    o(0x464c457f, 4); o(0x00010102, 4); o(0, 8);      /* magic, 64-bit, little-endian */
    o(2, 2); o(0x3e, 2); o(1, 4);                      /* executable, x86-64 */
    o(base + hdr, 8); o(64, 8); o(0, 8); o(0, 4);      /* entry point, header offsets, flags */
    o(64, 2); o(56, 2); o(1, 2); o(64, 2); o(0, 2); o(0, 2);
    /* program header: one segment, read/write/run */
    o(1, 4); o(7, 4); o(0, 8); o(base, 8); o(base, 8);
    o(total, 8); o(total, 8); o(0x1000, 8);
    for (int i = 0; i < nc; i++) out[no++] = code[i];
    for (int i = 0; i < nd; i++) out[no++] = data[i];

    char *path = argc > 2 ? argv[2] : "a.out";
    long ofd = sys(2, (long)path, 0x241, 0755);        /* open to write, create, empty it */
    if (ofd < 0) die("cannot write", path);
    sys(1, ofd, (long)out, no);
    sys(3, ofd, 0, 0);
    return 0;
}

__asm__(".globl _start\n_start:\n"
        "xor %ebp,%ebp\n mov %rsp,%rdi\n and $-16,%rsp\n call start_c\n");
void start_c(long *sp) {
    sys(60, qmain((int)sp[0], (char **)(sp + 1)), 0, 0);
}