#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#include <api/lcd.h>

typedef int __cdecl__ main_t(int argc, char **argv);

#define START 0x1100
#pragma data-name(push, "RODATA")
const byte *_STARTUP__ = (byte *)START;
#pragma data-name(pop)

extern byte fat16_open(const char *filename);
extern byte fat16_read(byte *dest);

// Built-ins
extern int cmd_ls(int argc, char **argv);
extern int cmd_peekpoke(int argc, char **argv);

#pragma bss-name(push, "ARGS")
byte argc;
char *argv[16];
char command[256 - sizeof(byte *) - sizeof(byte *[16])];
#pragma bss-name(pop)
/* byte argc; */
/* char *argv[16]; */
/* char argData[256]; */

/* int exec(const char *progname, const char *cmdline) { */
/*     byte err; */
/*     byte *dest = (byte *)START; */

/*     // TODO: pass cmdline args somehow */

/*     if ((err = fat16_open(progname))) { */
/*         puts("FAT16 open file error: "); */
/*         printhex(err); */
/*         cputc('\n'); */
/*         return 1; */
/*     } */

/*     while ((err = fat16_read(dest)) != 1) { */
/*         if (err) { */
/*             puts("FAT16 read file error: "); */
/*             printhex(err); */
/*             cputc('\n'); */
/*             return 1; */
/*         } */
/*         cputc('.'); */
/*         dest += 512; */
/*     } */
/*     puts("OK\n"); */

/*     __asm__("jsr %w", START); */

/*     // TODO */
/*     return 0; */
/* } */

int system(const char *s) {
    char *start = command;
    char *end = NULL;
    byte err;
    byte *dest = (byte *)START;
    byte arglen;
    byte dot_count = 0;

    end = start + strlen(s);

    if (end == start) {
        return 1;
    }

    strcpy(command, s);

    argc = 0;
    while (start < end) {
        arglen = strcspn(start, " ");
        if (!arglen) {
            // Empty argument, skip
            start++;
            continue;
        }

        argv[argc++] = start;
        start[arglen] = 0;
        start += arglen + 1;
    };
    if (!argc) {
        return 2;
    }

    // Built-ins
    if (!strcmp(argv[0], "ls")) {
        return cmd_ls(argc, argv);
    }
    if (!strcmp(argv[0], "?")) {
        return cmd_peekpoke(argc, argv);
    }

    if ((err = fat16_open(argv[0]))) {
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
        dot_count++;
        dest += 512;
    }
    while (dot_count--) {
        cputc(0x08);
    }

    /* __asm__("jsr %w", START); */
    // main() is __cdecl__ and cannot be __fastcall__
    /* ((int __cdecl__ (*)(int, char *[16]))(START))(argc, argv); */
    ((main_t *)START)(argc, argv);

    // TODO
    return 0;
}
