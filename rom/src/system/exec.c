#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#include <api/lcd.h>

#define START 0x1100
#pragma data-name(push, "RODATA")
const byte* _STARTUP__ = (byte*)START;
#pragma data-name(pop)

extern byte fat16_open(const char *filename);
extern byte fat16_read(byte *dest);

#pragma bss-name(push, "ARGS")
byte argc;
byte *argv[16];
char command[256 - sizeof(byte *) - sizeof(byte *[16])];
#pragma bss-name(pop)
/* byte argc; */
/* char *argv[16]; */
/* char argData[256]; */

int exec(const char *progname, const char *cmdline) {
    byte err;
    byte *dest = (byte*)START;

    // TODO: pass cmdline args somehow

    if ((err = fat16_open(progname))) {
        puts("FAT16 open file error: ");
        printhex(err);
        cputc('\n');
        return 1;
    }

    while ((err = fat16_read(dest)) != 1) {
        if (err) {
            puts("FAT16 read file error: ");
            printhex(err);
            cputc('\n');
            return 1;
        }
        cputc('.');
        dest += 512;
    }
    puts("OK\n");

    __asm__("jsr %w", START);

    // TODO
    return 0;
}

int system(const char *s) {
    strcpy(command, s);
    strchr(command, ' ');
    return exec(s, "");
}
