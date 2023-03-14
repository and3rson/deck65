.segment "IO"

;LCD
_OLD_LCD0:     .res  1
_OLD_LCD1:     .res  1
_OLD_LCD_BAD:  .res  254

; VIA
VIA1_RB:    .res  1
VIA1_RA:    .res  1
VIA1_DDRB:  .res  1
VIA1_DDRA:  .res  1
VIA1_T1CL:  .res  1
VIA1_T1CH:  .res  1
VIA1_T1LL:  .res  1
VIA1_T1LH:  .res  1
VIA1_T2CL:  .res  1
VIA1_T2CH:  .res  1
VIA1_SR:    .res  1
VIA1_ACR:   .res  1
VIA1_PCR:   .res  1
VIA1_IFR:   .res  1
VIA1_IER:   .res  1
VIA1_ORNH:  .res  1

.code

.scope via
init:
        phx

        ; ****************
        ; VIA - Common
        ; ****************
        ; Don't let T1 toggle PB7, PA, or PB latch
        ; lda VIA1_ACR
        ; and #$7C
        stz VIA1_ACR
        ; Keyboard interrupts with CB2
        lda VIA1_PCR
        ; ora #%00100000  ; CB2 - Independent interrupt input-negative edge (page 13)
        ora #%00000010  ; CA2 - Independent interrupt input-negative edge (page 13)
        ; and #%00011111  ; CB2 - Input-negative active edge (page 13)
        sta VIA1_PCR
        ; Enable interrupts for keyboard only
        lda #%01111111  ; Disable all interrupts
        sta VIA1_IER
        ; lda #%10001000  ; Set interrupt flag for CB2 (page 27)
        lda #%10000001  ; Set interrupt flag for CA2 (page 27)
        sta VIA1_IER

        ; ****************
        ; VIA - Port A
        ; ****************
        ; PS/2 Keyboard
        ;   CB2 - Clock
        ;   PA7      - data
        ; LCD
        ;   PA6      - RS
        ;   PA5      - R/W
        ;   PA4      - EN
        ;   PA3..PA0 - data
        lda #%10100000
        sta VIA1_RA
        lda #$FF
        sta VIA1_DDRA

        ; ****************
        ; VIA - Port B
        ; ****************
        ; SD Card
        ;   PB0 - MISO
        ;   PB1 - MOSI
        ;   PB2 - CS
        ;   PB3 - SCK
        lda #%00000100  ; Set CS high, all other bits - low
        sta VIA1_RB
        lda #%11111110  ; ; PB0 - input, PB1..PB3 - outputs
        sta VIA1_DDRB

        ; ****************
        ; VIA - Clear all interrupt flags
        ; ****************
        lda #$7F
        sta VIA1_IFR

        plx

        rts
.endscope
