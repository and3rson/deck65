#include <stdio.h>
#include <conio.h>

#include <api/i2c.h>
#include <api/lcd.h>

void main();

void main() {
    byte h, m, s;
    puts("Reading time...");
    i2c_start();
    if (i2c_write(0x68 << 1)) {
        puts(" err: send addr\n");
        return;
    }
    if (i2c_write(0x00)) {
        puts(" err: send reg\n");
        return;
    }
    i2c_start();
    if (i2c_write((0x68 << 1) | 1)) {
        puts(" err: send addr\n");
        return;
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
    return;
}
