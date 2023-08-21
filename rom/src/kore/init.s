;
; Kernel entrypoint
;

.include "../include/define.inc"

.export init
.export getps, _getps = getps

.importzp sp
.import BANKS, BANK_CNT
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

        ; Select first RAM bank
        ldx #<BANK_CNT
    @stz:
        dex
        stz BANKS, x
        bne @stz

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

        jsr lcd_printfz
        .byte "Testing banks... ", 0

        ; inc BANK
        ; lda #$AA
        ; sta $1000
        ; inc BANK
        ; lda #$BB
        ; sta $1000
        ;
        ; lda #$01
        ; sta BANK
        ; lda $1000
        ; stz BANK
        ; jsr lcd_printhex
        ;
        ; lda #$02
        ; sta BANK
        ; lda $1000
        ; stz BANK
        ; jsr lcd_printhex
        ;
        ; lda #$0A
        ; jsr lcd_printchar
        ;
        cli

        ; jsr lcd_printfz
        ; .asciiz "Writing AT cmd...\n"
        ; lda #'A'
        ; jsr acia_write
        ; lda #'T'
        ; jsr acia_write
        ; lda #13
        ; jsr acia_write
        ; lda #10
        ; jsr acia_write

        ; jsr lcd_printfz
        ; .asciiz "Writing byte...\n"
        ; jsr acia_read
        ; jsr lcd_printhex
        ; jsr lcd_printfz
        ; .asciiz "Writing byte...\n"
        ; jsr acia_read
        ; jsr lcd_printhex

        ; jsr i2c_start
        ; lda #($68 << 1)  ; %0101010
        ; jsr i2c_write
        ; lda #$00
        ; jsr i2c_write
        ; lda #$00
        ; jsr i2c_write
        ; lda #$00
        ; jsr i2c_write
        ; lda #$00
        ; jsr i2c_write
        ; ; lda #$DD
        ; ; jsr i2c_write
        ; jsr i2c_stop

    ; @next:
        ; jsr i2c_start
        ; lda #($68 << 1)  ; %0101010
        ; jsr i2c_write
        ; lda #0  ; Register 0
        ; jsr i2c_write

        ; jsr i2c_start
        ; lda #(($68 << 1) | 1)  ; %0101010
        ; jsr i2c_write
        ; jsr i2c_read_ack
        ; jsr i2c_read_nack
        ; jsr i2c_stop

        ; jsr wait1s
        ; jmp @next



        ;;;;;;;;;;
        ; jsr sdc_init
        ; bcc @sdc_ok
        ; jsr lcd_printfz
        ; .asciiz "SD card error: "
        ; lda sdc_ERR
        ; jsr lcd_printhex
        ; acall lcd_printchar, #10
        ; jmp @post_init
    ; @sdc_ok:

        ; jsr fat16_init
        ; bcc @fat16_ok
        ; jsr lcd_printfz
        ; .asciiz "FAT16 error: "
        ; lda fat16_ERR
        ; jsr lcd_printhex
        ; acall lcd_printchar, #10
        ; jmp @post_init
    ; @fat16_ok:

        ; jsr lcd_printfz
        ; .asciiz "FAT16 bootsector: "
        ; lda fat16_BOOTSEC+1
        ; jsr lcd_printhex
        ; lda fat16_BOOTSEC
        ; jsr lcd_printhex
        ; acall lcd_printchar, #10
        ;;;;;;;;;;



        ; jsr sdc_read_block_start
        ; cmp #0
        ; bne @read_err
        ; print SDC_BUFFER
        ; jmp @after_read
    ; @read_err:
        ; jsr lcd_printhex
    ; @after_read:

    @post_init:

        ; print S_BAR19

        jmp _urepl_main

        ; load song into RAM
        ldy #0
    @copy_byte:
        lda songdata,Y
        sta songdest,Y
        lda INIT_PTR
        inc
        sta INIT_PTR
        iny
        cpy #songlen
        bne @copy_byte

        jsr lcd_printfz
        .asciiz "Initializing...\n"

        ; init song
        jsr songinit

        ; print S_STARTING

        stz CNT
        lda #1
        sta DIR

    @play:
        ; play song
        jsr songplay

        ; print S_PROGRESS
        jsr wait16ms

        ; ldx CNT
        ; ldy DIR
        ; bne @inc
    ; @dec:
        ; lda #8
        ; jsr lcd_printchar
        ; dex
        ; bne @done
        ; lda #1
        ; sta DIR
        ; jmp @done
    ; @inc:
        ; lda #'+'
        ; jsr lcd_printchar
        ; inx
        ; cpx #19
        ; bne @done
        ; stz DIR
    ; @done:
        ; stx CNT
        jmp @play

        ; lda LCD0 ; for debug
        stp

    songstart:
; .incbin "./music/mca_vrolijke_vier.sid"
; this currently works only for songs <256 bytes
; .incbin "./music/Crue_Gurl_Freestyle_Remix.sid"
; .incbin "./music/Room_2.sid"
.incbin "./music/Splatform_256_bytes.sid"
    songend:

    songdata = songstart + $7E
    songlen = songend - songdata
    ; songdest = $0FFF
    ; songdest = $1000
    ; songinit = $1006
    ; songplay = $1000
    ; songdest = $10EB
    ; songinit = $10EB
    ; songplay = $1102
    songdest = $0328
    songinit = $032A
    songplay = $035E

    .byte $AA, $BB
    .word lcd_printz
    foo1: .byte >songstart
    foo2: .byte <songstart
    foo3: .byte >songdata
    foo4: .byte <songdata

; TODO: Basic basic
; TODO: LOAD from SD card
