.include "tn45def.inc"

.cseg
.org 0x00

        clr r17

        ldi r16,(1<<PINB4)
        out DDRB, r16

start:
        eor r17,r16
        out PORTB, r17
        rjmp start
