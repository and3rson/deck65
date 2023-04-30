#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#include <api/i2c.h>
#include <api/lcd.h>

/* extern byte argc; */
/* extern char *argv[16]; */

int main(int argc, char **argv);

int set_time(char **argv) {
    byte i, v;
    puts("Setting time...");
    i2c_start();
    if (i2c_write(0x68 << 1)) {
        puts(" err: send addr\n");
        i2c_stop();
        return 1;
    }
    if (i2c_write(0x00)) {
        puts(" err: send reg\n");
        i2c_stop();
        return 1;
    }
    for (i = 0; i < 3; i++) {
        v = atoi(argv[3 - i]);
        if (i2c_write(v)) {
            puts(" err: send reg\n");
            i2c_stop();
            return 0;
        }
    }
    i2c_stop();
    puts(" done\n");
    return 1;
}

int read_time() {
    byte h, m, s;
    puts("Reading time...");
    i2c_start();
    if (i2c_write(0x68 << 1)) {
        puts(" err: send addr\n");
        i2c_stop();
        return 1;
    }
    if (i2c_write(0x00)) {
        puts(" err: send reg\n");
        i2c_stop();
        return 1;
    }
    i2c_start();
    if (i2c_write((0x68 << 1) | 1)) {
        puts(" err: send addr\n");
        i2c_stop();
        return 1;
    }
    puts(" ");
    s = i2c_read(1);
    m = i2c_read(1);
    h = i2c_read(0);
    i2c_stop();
    s = s & 0x7F; // Remove CH flag
    printhex(h);
    puts(":");
    printhex(m);
    puts(":");
    printhex(s);
    puts("\n");
}

int main(int argc, char **argv) {
    if (argc == 4) {
        return set_time(argv);
    }
    return read_time();
}
