#include <stdio.h>
#include <conio.h>

#include <api/system.h>
#include <api/uart.h>
#include <api/lcd.h>
#include <api/keyboard.h>
#include <api/wait.h>

int main(int argc, char **argv);

byte echo = 0;
byte esc = 0;
byte crlf = 0;

extern void uart_reset();

int main(int argc, char **argv) {
    /* puts("Writing AT cmd...\n"); */
    /* acia_write('A'); */
    /* acia_write('T'); */
    /* acia_write(13); */
    /* acia_write(10); */
    byte c;
    /* *((byte *)0x1A) = 0; */
    /* uart_reset(); */
    while (1) {
        c = igetch();
        if (c == 0x1B) {
            esc = !esc;
            continue;
        }
        /* c = getps(); */
        /* printhex(getps); */
        if (c) {
            if (esc) {
                if (c == 'q') {
                    return 0;
                }
                if (c == 'e') {
                    echo = !echo;
                    if (echo) {
                        puts("Echo ON\n");
                    } else {
                        puts("Echo OFF\n");
                    }
                }
                if (c == 'n') {
                    crlf = !crlf;
                    if (crlf) {
                        puts("CRLF on\n");
                    } else {
                        puts("CRLF off\n");
                    }
                }
                esc = 0;
                continue;
            }

            if (echo) {
                cputc(c);
            }
            if (c == 10 && crlf) {
                uart_write(13);
                wait1ms();
                uart_write(10);
            } else {
                uart_write(c);
            }
        }
        if (uart_has_data()) {
            c = uart_get();
            if (c != 13) {
                cputc(c);
            }
        }
    }
    return 0;
}
