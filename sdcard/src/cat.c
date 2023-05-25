#include <stdio.h>
#include <conio.h>

#include <api/system.h>
#include <api/uart.h>
#include <api/lcd.h>
#include <api/keyboard.h>

int main(int argc, char **argv);

byte echo = 0;
byte esc = 0;

int main(int argc, char **argv) {
    byte c;
    while (1) {
        c = cgetc();
        if (c == 0x1B) {
            return 0;
        }
        printhex(c);
    }
    return 0;
}
