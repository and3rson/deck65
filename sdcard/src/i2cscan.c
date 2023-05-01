#include <stdio.h>
#include <conio.h>

#include <api/i2c.h>
#include <api/lcd.h>

int main(int argc, char **argv) {
    byte addr;
    byte first = 1;
    puts("Scanning I2C: ");
    for (addr = 1; addr <= 127; addr++) {
        i2c_start();
        if (!i2c_addr(addr, I2C_READ)) {
            if (!first) {
                puts(", ");
            }
            printhex(addr >> 1);
            first = 0;
        }
        i2c_stop();
    }
    if (first) {
        puts("(none)");
    }
    cputc('\n');
    return 0;
}
