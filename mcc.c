/* mcc - micro C compiler for Linux x86-64. No libc.
 * Build:  gcc -static -nostdlib -ffreestanding -fno-stack-protector -O1 -o mcc mcc.c
 * Use:    ./mcc in.c [out]    (out defaults to a.out)
 * Reads:  int main() { int i = 0; while (i < 3) { putn(i); i = i + 1; } return i; }
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

/* Local variables live on the stack, 4 bytes each: the first at [rbp-4], the
 * second at [rbp-8], and so on. A variable's position in this table is all that's
 * needed to find it again. vname holds the names, nvar says how many there are.
 *
 * A { } block gets its own scope: variables declared inside it vanish at the
 * closing brace, and their stack slots get reused. scope is the first variable
 * that belongs to the current block, and maxvar is the most variables alive at
 * once, which decides how much stack space the function needs. */
static char vname[64][32];
static int nvar, scope, maxvar;
static char name[32];                   /* the name ident() just read */
static char *p;

static long slen(char *s) { long n = 0; while (s[n]) n++; return n; }
static void err(char *s) { sys(1, 2, (long)s, slen(s)); }
static void die(char *m, char *x) {
    err("mcc: "); err(m); if (x) { err(" '"); err(x); err("'"); } err("\n");
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
            p += 2;
            while (*p && !(p[0] == '*' && p[1] == '/')) p++;
            if (!*p) die("unterminated comment", 0);
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

/* Variable number i sits at [rbp - 4*(i+1)]. These copy it into eax and back. */
static void load(int i)  { emit(0x8b); emit(0x85); emit32(-4 * (i + 1)); }   /* eax = the variable */
static void store(int i) { emit(0x89); emit(0x85); emit32(-4 * (i + 1)); }   /* the variable = eax */

static void exit_with(u32 code_) {
    emit(0xbf); emit32(code_);          /* edi = exit code */
    emit(0xb8); emit32(60);             /* eax = 60 (exit) */
    emit(0x0f); emit(0x05);             /* syscall */
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

/* exit with whatever is in eax */
static void exit_eax(void) {
    emit(0x89); emit(0xc7);             /* edi = eax */
    emit(0xb8); emit32(60);             /* eax = 60 (exit) */
    emit(0x0f); emit(0x05);             /* syscall */
}

/* Expressions. Every function leaves its answer in eax.
 * For "a op b": work out a, push it, work out b, move b to ecx, pop a, do the op. */
static void expr(void);

static void factor(void) {
    ws();
    if (eat("(")) { expr(); expect(")"); }
    else if (eat("-")) { factor(); emit(0xf7); emit(0xd8); }       /* neg eax */
    else if (*p >= '0' && *p <= '9') {
        u32 v = 0;
        while (*p >= '0' && *p <= '9') v = v * 10 + (*p++ - '0');
        emit(0xb8); emit32(v);                                      /* eax = number */
    } else if (isw(*p)) { ident(); load(lookup()); }                /* a variable */
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

/* == and != are the loosest, so this is the top: a whole expression. */
static void expr(void) {
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
static int jump(void) { emit(0xe9); emit32(0); return nc - 4; }
static void jump_back(int target) {     /* a jump to code that's already been written */
    emit(0xe9);
    emit32(target - (nc + 4));
}
static void here(int at) {
    u32 rel = nc - (at + 4);            /* distances count from the end of the jump instruction */
    for (int k = 0; k < 4; k++) code[at + k] = rel >> (8 * k);
}

static void stmt(void) {
    if (eat("puts")) {
        expect("("); expect("\"");
        int start = nd;
        for (;;) {
            char c = *p++;
            if (!c) die("unterminated string", 0);
            if (c == '"') break;
            if (c == '\\') {
                c = *p++;
                if (c == 'n') c = 10; else if (c == 't') c = 9; else if (c == '0') c = 0;
            }
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
        expr();
        expect(";");
        exit_eax();
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
    } else if (eat("int")) {
        /* int x;  or  int x = <expression>;
         * Reserve a slot for the name. "int x;" on its own makes no code, so the
         * slot keeps whatever was there before, like in C. A name can only clash
         * with one from the same block, so an inner block may reuse an outer name. */
        ident();
        if (find(scope) >= 0) die("already declared", name);
        if (nvar == 64) die("too many variables", 0);
        int i = nvar++;
        if (nvar > maxvar) maxvar = nvar;
        for (int j = 0; j < 32; j++) vname[i][j] = name[j];
        if (eat("=")) { expr(); store(i); }
        expect(";");
    } else {
        /* x = <expression>;  Work out the value and save it into x. */
        ws();
        if (!isw(*p)) die("unsupported statement", 0);
        ident();
        int i = lookup();
        expect("="); expr(); expect(";");
        store(i);
    }
}

static int qmain(int argc, char **argv) {
    if (argc < 2) die("usage: mcc in.c [out]", 0);
    long fd = sys(2, (long)argv[1], 0, 0);
    if (fd < 0) die("cannot open", argv[1]);
    long n = sys(0, fd, (long)src, sizeof src - 1);
    if (n < 0) die("read failed", 0);
    src[n] = 0;
    p = src;

    /* Start of main: make room on the stack for the variables. The number of them
     * isn't known until the whole function has been read, so the amount is left
     * blank here and filled in afterwards. */
    expect("int"); expect("main"); expect("("); eat("void"); expect(")"); expect("{");
    emit(0x55);                                         /* save rbp */
    emit(0x48); emit(0x89); emit(0xe5);                 /* rbp = rsp, so variables can be found relative to rbp */
    emit(0x48); emit(0x81); emit(0xec);                 /* move rsp down to make room for them */
    int frame_at = nc; emit32(0);                       /* the amount, filled in below */
    while (!eat("}")) stmt();
    exit_with(0);
    u32 frame = (maxvar * 4 + 15) & ~15;                /* 4 bytes each, rounded up to a multiple of 16 */
    for (int k = 0; k < 4; k++) code[frame_at + k] = frame >> (8 * k);

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