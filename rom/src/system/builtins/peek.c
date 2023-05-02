#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#include <api/types.h>
#include <api/functions.h>
#include <api/lcd.h>

extern byte fat16_opendir();
extern byte fat16_readdir();
extern fat_entry_t *fat16_direntry();

int cmd_peekpoke(int argc, char **argv) {
    byte lo, hi;
    word addr;
    char *arg = argv[1];
    if (argc != 2) {
        puts("Usage: ? ADDR[=VALUE]\n");
        return 1;
    }
    hi = f_parse_octet(arg);
    lo = f_parse_octet(arg + 2);
    addr = (hi << 8) | lo;
    printword(addr);
    puts(" = ");
    printhex(*((word *)addr));
    if (strlen(arg) > 4) {
        lo = f_parse_octet(arg + 5);
        *((word *)addr) = lo;
        puts(" -> ");
        printhex(lo);
    }
    cputc('\n');
    return 0;
}
