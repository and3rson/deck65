;
; 6502 vectors
;

.ifndef __SIM65C02__
; Vectors are not needed for Sim65
.segment "VECTORS"

.word nmi   ; nmi
.word init  ; main code
.word irq   ; interrupt handler
.endif
