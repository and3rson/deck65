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
extern void printhex(byte hex);

int main() {
    byte h, m, s;
    puts("Reading time...");
    i2c_start();
    if (i2c_write(0x68 << 1)) {
        puts(" err: send addr\n");
        return 0;
    }
    if (i2c_write(0x00)) {
        puts(" err: send reg\n");
        return 0;
    }
    i2c_start();
    if (i2c_write((0x68 << 1) | 1)) {
        puts(" err: send addr\n");
        return 0;
    }
    puts("\nTime: ");
    s = i2c_read(1);
    m = i2c_read(1);
    h = i2c_read(0);
    i2c_stop();
    s = s & 0x7F;  // Remove CH flag
    printhex(h);
    puts(":");
    printhex(m);
    puts(":");
    printhex(s);
    puts("\n");
    return 0;
}
