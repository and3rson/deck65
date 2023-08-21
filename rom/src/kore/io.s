;
; Memory-mapped I/O stuff - VIA, SID, etc
;

.export BANKS, BANK_A, BANK_B, BANK_C, BANK_D, BANK_CNT
.export VIA1_RB
.export VIA1_RA
.export VIA1_DDRB
.export VIA1_DDRA
.export VIA1_IFR
.export LCD1_DATA
.export LCD1_CMD
.export ACIA1_DATA
.export ACIA1_STAT
.export acia_write

.export io_init = init
; .export acia_write
; .export _acia_write = acia_write
; .export acia_read
; .export _acia_read = acia_read
; .export acia_iread
; .export _acia_iread = acia_iread

.segment "IO"

; LCD
; _OLD_LCD0:     .res  1
; _OLD_LCD1:     .res  1
; _OLD_LCD_BAD:  .res  254

; $D000-$D0FF
; RAM banking register
BANKS:
BANK_A: .res 1
BANK_B: .res 1
BANK_C: .res 1
BANK_D: .res 1
BANK_CNT = * - BANKS
.align 256

; $D100-$D1FF
; VIA
VIA1_RB:   .res 1
VIA1_RA:   .res 1
VIA1_DDRB: .res 1
VIA1_DDRA: .res 1
VIA1_T1CL: .res 1
VIA1_T1CH: .res 1
VIA1_T1LL: .res 1
VIA1_T1LH: .res 1
VIA1_T2CL: .res 1
VIA1_T2CH: .res 1
VIA1_SR:   .res 1
VIA1_ACR:  .res 1
VIA1_PCR:  .res 1
VIA1_IFR:  .res 1
VIA1_IER:  .res 1
VIA1_ORNH: .res 1
.align 256

; $D200-$D2FF
; ACIA
ACIA1_DATA: .res 1
ACIA1_STAT: .res 1
ACIA1_CMD:  .res 1
ACIA1_CTRL: .res 1
.align 256

; $D300-$D3FF
; 240x64 LCD (T6963C)
LCD1_DATA: .res 1
LCD1_CMD:  .res 1
.align 256

; $D400-$D4FF
; Reserved for SID

.segment "KORE"

init:
        pha
        phx

        ; ****************
        ; Initialize VIA
        ; ****************

        ; VIA - Common
        ;
        ; Don't let T1 toggle PB7, PA, or PB latch
        ; lda VIA1_ACR
        ; and #$7C
        stz VIA1_ACR
        ; Keyboard interrupts with CB2
        lda VIA1_PCR
        ora #%00100000  ; CB2 - Independent interrupt input-negative edge (page 13)
        ; ora #%00000010  ; CA2 - Independent interrupt input-negative edge (page 13)
        ; and #%00011111  ; CB2 - Input-negative active edge (page 13)
        sta VIA1_PCR
        ; Enable interrupts for keyboard only
        lda #%01111111  ; Disable all interrupts
        sta VIA1_IER
        lda #%10001000  ; Set interrupt flag for CB2 (page 27)
        ; lda #%10000001  ; Set interrupt flag for CA2 (page 27)
        sta VIA1_IER
        ; Disable shift register
        stz VIA1_SR

        ; VIA - Port A
        ;
        ; Misc
        ;   PA7      - high during ISR
        ;   PA6..PA0 - output
        lda #%00000000
        sta VIA1_RA
        lda #$FF
        sta VIA1_DDRA

        ; VIA - Port B
        ;
        ; I2C
        ;   PB5 - data
        ;   PB6 - clock
        ; PS/2 Keyboard
        ;   CB2 - clock
        ;   PB4 - data
        ; SD Card
        ;   PB0 - MISO
        ;   PB1 - MOSI
        ;   PB2 - SCK
        ;   PB3 - CS
        lda #%00001000  ; Set CS (SPI) high, all other bits (including SDA/SCL) - low
        sta VIA1_RB
        lda #%10001110  ; ; PB0+PB4+PB5+PB6 - input, PB1..PB3 - outputs
        sta VIA1_DDRB

        ; ****************
        ; VIA - Clear all interrupt flags
        ; ****************
        lda #$7F
        sta VIA1_IFR

        ; ****************
        ; Initialize ACIA
        ; ****************

        ; Soft reset
        stz ACIA1_STAT

        ; Set modes & functions
        ; lda #$0B  ; no parity, no echo, no Tx interrupt, no Rx interrupt, enable Tx/Rx
        lda #$09  ; no parity, no echo, no Tx interrupt, enable Rx interrupt, enable Tx/Rx
        sta ACIA1_CMD

        ; Set mode
        lda #$1E  ; 8-N-1, 9600 baud
        sta ACIA1_CTRL

        ; lda #$12
        ; jsr acia_write
        ; lda #$34
        ; jsr acia_write
        ; lda #$56
        ; jsr acia_write
        ; lda #$78
        ; jsr acia_write
        ; lda #$9A
        ; jsr acia_write
        ; lda #$BC
        ; jsr acia_write
        ; lda #$DE
        ; jsr acia_write
        ; lda #$F0

        plx
        pla

        rts

; Write byte to TX buffer
;
; Arguments:
;   A - byte
acia_write:
        pha

    @wait:
        lda ACIA1_STAT
        and #$10
        beq @wait

        pla

        sta ACIA1_DATA

        rts

;; Read byte from RX buffer
;;
;; Return:
;;   A - byte
;acia_read:
;        lda ACIA1_STAT
;        and #$08
;        beq acia_read

;        lda ACIA1_DATA

;        rts


;; Read byte from RX buffer (non-blocking)
;;
;; Return:
;;   A - byte, 0 if not ready
;acia_iread:
;        lda ACIA1_STAT
;        and #$08
;        beq @empty

;        lda ACIA1_DATA
;        jmp @end

;    @empty:
;        lda #0

;    @end:
;        rts
