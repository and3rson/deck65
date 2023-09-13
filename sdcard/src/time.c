#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#include <api/i2c.h>
#include <api/lcd.h>

// https://www.analog.com/media/en/technical-documentation/data-sheets/DS1307.pdf

int main(int argc, char **argv);

typedef union {
    struct {
        int secL : 4; // BCD low
        int secH : 3; // BCD high
        int ch : 1; // 0 = enable clock
    } fields;
    byte value;
} reg0;
typedef union {
    struct {
        int minL : 4; // BCD low
        int minH : 3; // BCD high
        int zero : 1;
    } fields;
    byte value;
} reg1;
typedef union {
    struct {
        int hourL : 4; // BCD low
        int hourH : 2; // BCD high
        int mode : 1;  // 0 = 24-hour mode
        int zero : 1;
    } fields;
    byte value;
} reg2_24h;
typedef union {
    struct {
        int hourL : 4; // BCD low
        int hourH : 1; // BCD high
        int ampm : 1;  // 0 = AM, 1 = PM
        int mode : 1;  // 1 = 12-hour mode
        int zero : 1;
    } fields;
    byte value;
} reg2_ampm;

int set_time(char **argv) {
    byte v;
    reg0 sreg;
    reg1 mreg;
    reg2_24h hreg;

    // puts("Setting time...");
    i2c_start();

    if (i2c_writereg(0x68, 0x00)) {
        puts(" err: start write reg\n");
        i2c_stop();
        return 1;
    }

    // Seconds
    v = atoi(argv[3]);
    sreg.fields.secL = v % 10;
    sreg.fields.secH = v / 10;
    sreg.fields.ch = 0;
    if (i2c_write(sreg.value)) {
        puts(" err: write reg0\n");
        i2c_stop();
        return 1;
    }

    // Minutes
    v = atoi(argv[2]);
    mreg.fields.minL = v % 10;
    mreg.fields.minH = v / 10;
    mreg.fields.zero = 0;
    if (i2c_write(mreg.value)) {
        puts(" err: write reg1\n");
        i2c_stop();
        return 1;
    }

    // Hours
    v = atoi(argv[1]);
    hreg.fields.hourL = v % 10;
    hreg.fields.hourH = v / 10;
    hreg.fields.mode = 0; // 24-hour mode
    hreg.fields.zero = 0;
    if (i2c_write(hreg.value)) {
        puts(" err: write reg2\n");
        i2c_stop();
        return 1;
    }
    // printhex(hreg.value);
    // printhex(mreg.value);
    // printhex(sreg.value);

    i2c_stop();
    puts("Time set\n");
    return 0;
}

int read_time() {
    reg0 sreg;
    reg1 mreg;
    reg2_24h hreg;
    // puts("Reading time...");
    i2c_start();
    if (i2c_readreg(0x68, 0x00)) {
        puts(" err: start read reg\n");
        i2c_stop();
        return 1;
    }
    // puts(" ");
    sreg.value = i2c_read(1);
    mreg.value = i2c_read(1);
    hreg.value = i2c_read(0);
    i2c_stop();
    printnibble(hreg.fields.hourH);
    printnibble(hreg.fields.hourL);
    puts(":");
    printnibble(mreg.fields.minH);
    printnibble(mreg.fields.minL);
    puts(":");
    printnibble(sreg.fields.secH);
    printnibble(sreg.fields.secL);
    puts("\n");
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 4) {
        return set_time(argv);
    }
    return read_time();
}
