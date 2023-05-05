#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#include <api/i2c.h>
#include <api/lcd.h>
#include <api/wait.h>

/*
 * Reference:
 * https://github.com/adafruit/Adafruit_BME280_Library/blob/master/Adafruit_BME280.h
 * https://github.com/adafruit/Adafruit_BME280_Library/blob/master/Adafruit_BME280.cpp
 */

#define REG_CHIPID 0xD0
#define REG_SOFTRESET 0xE0
#define REG_STATUS 0XF3

int main(int argc, char **argv);

int fail(const char *message) {
    puts(message);
    i2c_stop();
    return 1;
}

int main(int argc, char **argv) {
    byte sensor_id, status;

    // Check sensor ID
    i2c_start();
    if (i2c_readreg(0x76, REG_CHIPID)) {
        return fail("err: start read reg\n");
    }
    sensor_id = i2c_read(0);
    if (sensor_id != 0x60) {
        // Sensor ID mismatch
        puts("Sensor ID: ");
        printhex(sensor_id);
        return fail("\nerr: sensor ID mismatch\n");
    }
    i2c_stop();

    // Soft reset
    i2c_start();
    if (i2c_writereg(0x76, REG_SOFTRESET)) {
        return fail("err: send write reg\n");
    }
    if (i2c_write(0xB6)) {
        return fail("err: write soft reset\n");
    }
    i2c_stop();

    // Wait for readiness
    wait16ms();

    // Check if still calibrating
    while (1) {
        i2c_start();
        if (i2c_readreg(0x76, REG_STATUS)) {
            return fail("err: send read reg\n");
        }
        status = i2c_read(0);
        if (status & 1) {
            // Still busy
            continue;
        }
        i2c_stop();
        break;
    }

    return 0;
}
