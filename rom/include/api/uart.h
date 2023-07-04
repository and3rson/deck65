#ifndef UART_H
#define UART_H

#include "./types.h"

// TODO: Use serial.h instead?

/* extern void acia_write(byte b); */
/* extern byte acia_read(); */
/* extern byte acia_iread(); */
extern void uart_write(byte b);
extern byte uart_has_data();
/* extern byte uart_iget(); */
extern byte uart_get();

#endif
