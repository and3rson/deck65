;
; Kernel entrypoint
;

.zeropage

CNT: .res 1
DIR: .res 1

.code

; S_BAR19: .asciiz "===================\n"
S_SYSTEM: .asciiz "       65ad02\n"
S_SDC_ERR: .asciiz "SD card err: "
S_FAT16_ERR: .asciiz "FAT16 err: "
S_FAT16_BOOTSEC: .asciiz "FAT16 bootsec: "

; Kernel entrypoint
;
; Arguments: none
init:
        sei

        ; Illegal nop test
        ; Can be used for banking
        ; https://laughtonelectronics.com/Arcana/KimKlone/Kimklone_opcode_mapping.html
        .byte $C2, $42

        jsr via::init

        jsr kbd::init

        jsr lcd::init

        jsr sdc::init
        bcc @sdc_ok
        print S_SDC_ERR
        lda sdc::ERR
        jsr lcd::printhex
        a8call lcd::printchar, #10
        jmp @post_init
    @sdc_ok:

        jsr fat16::init
        bcc @fat16_ok
        lda fat16::ERR
        print S_FAT16_ERR
        jsr lcd::printhex
        a8call lcd::printchar, #10
        jmp @post_init
    @fat16_ok:

        print S_FAT16_BOOTSEC
        lda fat16::BOOTSEC+1
        jsr lcd::printhex
        lda fat16::BOOTSEC
        jsr lcd::printhex
        a8call lcd::printchar, #10

        ; jsr sdc::read_block_start
        ; cmp #0
        ; bne @read_err
        ; print SDC_BUFFER
        ; jmp @after_read
    ; @read_err:
        ; jsr lcd::printhex
    ; @after_read:

    @post_init:
        cli

        print S_SYSTEM
        ; print S_BAR19

        jmp repl_main

        ; load song into RAM
        ldy #0
    @copy_byte:
        lda songdata,Y
        sta songdest,Y
        lda PTR
        inc
        sta PTR
        iny
        cpy #songlen
        bne @copy_byte

        print S_INITIALIZING

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
        ; jsr lcd::printchar
        ; dex
        ; bne @done
        ; lda #1
        ; sta DIR
        ; jmp @done
    ; @inc:
        ; lda #'+'
        ; jsr lcd::printchar
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
    .word lcd::printz
    foo1: .byte >songstart
    foo2: .byte <songstart
    foo3: .byte >songdata
    foo4: .byte <songdata

; TODO: Basic basic
; TODO: LOAD from SD card
