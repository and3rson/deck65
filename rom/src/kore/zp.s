;
; Zeropage
;
; This file helps to enforce all necessary paddings in zeropage.
;

.zeropage

; .org 0

; 6510 register area
; .res 3
; Reserve for SID music
; .res 125

; Zeropage for C programs

; .globalzp sp, sreg, regsave
; .globalzp ptr1, ptr2, ptr3, ptr4
; .globalzp tmp1, tmp2, tmp3, tmp4

; sp:             .res    2       ; Stack pointer
; sreg:           .res    2       ; Secondary register/high 16 bit for longs
; regsave:        .res    4       ; Slot to save/restore (E)AX into
; ptr1:           .res    2
; ptr2:           .res    2
; ptr3:           .res    2
; ptr4:           .res    2
; tmp1:           .res    1
; tmp2:           .res    1
; tmp3:           .res    1
; tmp4:           .res    1
; regbank:        .res    6

; .reloc
