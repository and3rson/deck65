#include <stdio.h>
#include <conio.h>
#include <string.h>

#include <api/keyboard.h>
#include <api/lcd.h>

char buff[40];
byte buffPos;

short a;
short b;

// TODO
const short _STARTUP__ = 0x1000;

extern byte fat16_init();
extern byte fat16_open(char *filename);
extern byte fat16_read(byte *dest);

void urepl_main() {
    char c;
    char err;
    byte *dest;
    dest = (byte *)0x1000;

    buffPos = 0;

    puts("MicroREPL READY.\n");

    if ((err = fat16_init())) {
        puts("FAT16 error: ");
        printhex(err);
        cputc('\n');
    }

    if ((err = fat16_open("snake"))) {
        puts("FAT16 open file error: ");
        printhex(err);
        cputc('\n');
    }

    while ((err = fat16_read(dest)) != 1) {
        if (err) {
            puts("FAT16 read file error: ");
            printhex(err);
            cputc('\n');
            break;
        }
        cputc('.');
        dest += 512;
    }
    puts("OK\n");

    printhex(*(byte*)0x1000);
    printhex(*(byte*)0x1001);
    printhex(*(byte*)0x1002);
    printhex(*(byte*)0x1003);
    printhex(*(byte*)0x1004);

    __asm__("jsr $1000");

    puts("$>");
    while (1) {
        c = cgetc();
        if (c == 8) {
            // Backspace
            if (buffPos > 0) {
                buffPos--;
                cputc(c);
            }
        } else if (c == 10) {
            // Execute
            buff[buffPos] = 0;
            cputc(0xA);
            if (strlen(buff)) {
                puts(buff);
                cputc(0xA);
            }
            buffPos = 0;
            puts("$>");
        } else {
            // TODO: Limit max length
            buff[buffPos++] = c;
            cputc(c);
        }
    }
}
