;
; Kernel entrypoint
;

.include "../include/define.inc"

.export init
.export getps, _getps = getps

.importzp sp
.import SEG_BANKS, SEGA_BANK, SEGB_BANK, SEG_CNT
.import init_jmpvec
.import __STACK_START__
.import lcd_printz
.import wait16ms
; .importzp fat16_ERR
; .import fat16_init
; .importzp fat16_BOOTSEC
.import lcd_printchar
.import lcd_printhex
.import lcd_printfz
.importzp sdc_ERR
.import sdc_init
.import i2c_init
.import lcd_init
.import kbd_init
.import io_init
.import uart_init
.import acia_write
.import acia_read
.import _urepl_main

.zeropage

CNT: .res 1
DIR: .res 1
INIT_PTR: .res 2

.segment "KORE"

getps:
        php
        pla
        rts

; Kernel entrypoint
;
; Arguments: none
init:
        sei

        ; Init segments to first banks
        ldx #<SEG_CNT
    @init_banks:
        dex
        stz SEG_BANKS, x
        bne @init_banks

        ; Initialize software stack
        lda #<(__STACK_START__)
        sta sp
        lda #>(__STACK_START__)
        sta sp+1
        jsr init_jmpvec

        ; Illegal nop test
        ; Can be used for banking
        ; https://laughtonelectronics.com/Arcana/KimKlone/Kimklone_opcode_mapping.html
        .byte $C2, $42

        jsr io_init
        jsr uart_init
        jsr kbd_init
        jsr lcd_init
        jsr i2c_init
        jsr sdc_init

        jsr lcd_printfz
        .byte "               ",$81," Deck65 ",$81,"\n",0
        jsr lcd_printfz
        .byte "             by Andrew Dunai  \n",0

        ; Test '670 banking
        jsr lcd_printfz
        .byte "Testing RAM banking... ", 0

        lda #0
        sta SEGB_BANK
        lda #$B0
        sta $2000
        lda #$C0
        sta $4000

        inc SEGB_BANK
        lda #$B1
        sta $2000
        lda #$C1
        sta $4000

        dec SEGB_BANK

        lda $2000  ; Should load $B0
        cmp #$B0
        bne @bank_fail

        lda $4000  ; Should load $C1
        cmp #$C1
        bne @bank_fail

        bra @bank_ok

    @bank_fail:
        pha
        jsr lcd_printfz
        .byte "ERR, GOT ", 0
        pla
        jsr lcd_printhex
        lda #10
        jsr lcd_printchar
        bra @bank_done
    @bank_ok:
        jsr lcd_printfz
        .byte "OK!\n", 0
    @bank_done:

        cli

        ; Jump to OS
        jmp _urepl_main
