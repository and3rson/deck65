#ifndef I2C_H
#define I2C_H

#include "./types.h"

#define I2C_READ 1
#define I2C_WRITE 0

extern void i2c_start();
extern void i2c_stop();
extern byte i2c_addr(byte addr, byte r_w);
extern byte i2c_write(byte data);
extern byte i2c_read(byte ack);

#endif
