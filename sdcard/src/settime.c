#include <stdio.h>
#include <conio.h>

// https://cc65.github.io/doc/cc65.html
/* #pragma code-name ("PROGRAM") */
/* #pragma rodata-name ("PROGRAM") */

int main();

typedef unsigned char byte;

extern void i2c_start();
extern void i2c_stop();
extern byte i2c_write(byte data);
extern byte i2c_read(byte ack);

int main() {
    byte i;
    puts("Setting time...");
    i2c_start();
    if (i2c_write(0x68 << 1)) {
        puts(" err: send addr\n");
        return 0;
    }
    for (i = 0; i <= 6; i++) {
        if (i2c_write(0x00)) {
            puts(" err: send reg\n");
            return 0;
        }
    }
    i2c_stop();
    puts(" done\n");
    return 0;
}
