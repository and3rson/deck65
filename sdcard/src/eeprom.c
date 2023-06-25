#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#include <api/i2c.h>
#include <api/lcd.h>

int main(int argc, char **argv);

int stop(const char *msg, int code) {
    puts(msg);
    i2c_stop();
    return code;
}

int ee_write(word addr, byte value) {
    i2c_start();
    if (i2c_addr(0x50, 0)) return stop("err: write addr\n", 1);
    if (i2c_write((addr >> 8) & 0xFF)) return stop("err: write high addr\n", 1);
    if (i2c_write(addr & 0xFF)) return stop("err: write high addr\n", 1);
    if (i2c_write(value)) return stop("err: write value\n", 1);
    i2c_stop();
    return 0;
}

int ee_read(word addr) {
    byte value;
    i2c_start();
    if (i2c_addr(0x50, 0)) return stop("err: write addr\n", 1);
    if (i2c_write((addr >> 8) & 0xFF)) return stop("err: write high addr\n", 1);
    if (i2c_write(addr & 0xFF)) return stop("err: write high addr\n", 1);
    i2c_start();
    if (i2c_addr(0x50, 1)) return stop("err: read addr\n", 1);
    value = i2c_read(0);
    i2c_stop();
    puts("Value: ");
    printhex(value);
    cputc('\n');
    return 0;
}

int main(int argc, char **argv) {
    word addr;
    byte value;
    if (argc == 3 && argv[1][0] == 'r') {
        // Read
        addr = atoi(argv[2]);
        return ee_read(addr);
    }
    if (argc == 4 && argv[1][0] == 'w') {
        // Write
        addr = atoi(argv[2]);
        value = atoi(argv[3]);
        ee_write(addr, value);
        return 0;
    }
    puts("Usage: eeprom (r|w) ADDR [VALUE]\n");
    return 1;
}
