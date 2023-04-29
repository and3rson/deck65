#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>

#include <api/keyboard.h>
#include <api/lcd.h>

char buff[40];
byte buffPos;

short a;
short b;

extern byte fat16_init();

void urepl_main() {
    char c;
    char err;
    byte *dest;

    buffPos = 0;

    puts("MicroREPL READY.\n");

    if ((err = fat16_init())) {
        puts("FAT16 error: ");
        printhex(err);
        cputc('\n');
    }

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
                system(buff);
                /* puts(buff); */
                /* cputc(0xA); */
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
