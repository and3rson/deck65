#ifndef I2C_H
#define I2C_H

#include "./types.h"

extern void i2c_start();
extern void i2c_stop();
extern byte i2c_write(byte data);
extern byte i2c_read(byte ack);

#endif
