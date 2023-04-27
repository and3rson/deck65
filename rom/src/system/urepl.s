;
; Simple interactive REPL shell & memory monitor
;

.include "../include/define.inc"

.import lcd_printchar
.import lcd_printhex
.import lcd_printfz
.import lcd_BUFFER_PREV
.import fat16_open
.import fat16_read
.importzp fat16_ERR
.importzp fat16_F_SIZE
.import kbd_getch
.import f_parse_octet
.import f_parse_hex

.export urepl_main

.zeropage

PTR: .res 2
DAT: .res 1

.segment "PROG"

APP_START = $1000
__STARTUP__ = $1000
.export __STARTUP__

.segment "SYSTEM"

jt_count .set 0
.macro jmptbl char, addr
    .repeat char - jt_count
        .word cmd_err
    .endrep
    .word addr
    jt_count .set char + 1
.endmacro

CMD_JUMPTABLE:
    jmptbl ' ', cmd_noop
    jmptbl '!', cmd_writemem
    jmptbl '?', cmd_printmem
    jmptbl 'f', cmd_find
    jmptbl 'j', cmd_jmp
    jmptbl 'm', cmd_printmem
    jmptbl 'r', cmd_run

.align 256

.segment "SYSTEM"

cmd_noop:
        jmp cmd_done


cmd_err:
        jsr lcd_printfz
        .asciiz "Unknown cmd: "
        acall lcd_printchar, lcd_BUFFER_PREV
        acall lcd_printchar, #' '
        acall lcd_printchar, #'('
        acall lcd_printhex, lcd_BUFFER_PREV
        acall lcd_printchar, #')'
        acall lcd_printchar, #10
        jmp cmd_done


cmd_printmem:
        lda #<(lcd_BUFFER_PREV+1)
        ldx #>(lcd_BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd_BUFFER_PREV+3)
        ldx #>(lcd_BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        acall lcd_printhex, PTR+1
        acall lcd_printhex, PTR
        acall lcd_printchar, #':'

        ldy #0
    @rep1:
        lda (PTR), Y
        jsr lcd_printhex
        acall lcd_printchar, #' '
        iny
        cpy #8
        bne @rep1

        acall lcd_printchar, #'['

        ldy #0
    @rep2:
        lda (PTR), Y
        cmp #32
        bcc @fix  ; <32
        cmp #126
        bcs @fix  ; >= 128
        jmp @print
    @fix:
        lda #'.'
    @print:
        jsr lcd_printchar
        iny
        cpy #8
        bne @rep2

        acall lcd_printchar, #']'
        acall lcd_printchar, #10

        jmp cmd_done


cmd_writemem:
        lda #<(lcd_BUFFER_PREV+1)
        ldx #>(lcd_BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd_BUFFER_PREV+3)
        ldx #>(lcd_BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        lda #<(lcd_BUFFER_PREV+6)
        ldx #>(lcd_BUFFER_PREV+6)
        jsr f_parse_octet

        sta (PTR)

        jmp cmd_done


cmd_jmp:
        lda #<(lcd_BUFFER_PREV+1)
        ldx #>(lcd_BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd_BUFFER_PREV+3)
        ldx #>(lcd_BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        jsr lcd_printfz
        .asciiz "JMP to: "
        acall lcd_printhex, PTR+1
        acall lcd_printhex, PTR
        acall lcd_printchar, #10

        jmp (PTR)


cmd_find:
        lda #<(lcd_BUFFER_PREV+1)
        ldx #>(lcd_BUFFER_PREV+1)
        jsr fat16_open
        bcs @not_found
        acall lcd_printhex, fat16_F_SIZE+3
        acall lcd_printhex, fat16_F_SIZE+2
        acall lcd_printhex, fat16_F_SIZE+1
        acall lcd_printhex, fat16_F_SIZE
        acall lcd_printchar, #10
        jmp @end

    @not_found:
        jsr lcd_printfz
        .asciiz "Not found: "
        lda fat16_ERR
        jsr lcd_printhex
        lda #10
        jsr lcd_printchar

    @end:
        jmp cmd_done

cmd_run:
        lda #<(lcd_BUFFER_PREV+1)
        ldx #>(lcd_BUFFER_PREV+1)
        jsr fat16_open
        bcs @not_found

        lda #<APP_START
        sta PTR
        lda #>APP_START
        sta PTR+1
    @read:

        ;
        ; lda fat16_F_CLU
        ; jsr lcd_printhex
        ; lda fat16_F_CLU+1
        ; jsr lcd_printhex
        lda #'.'
        jsr lcd_printchar
        ;

        lda PTR
        ldx PTR+1
        jsr fat16_read
        bcs @read_failed
        cmp #1  ; has more data
        bne @done
        clc
        lda PTR+1
        adc #2
        sta PTR+1
        jmp @read
    @done:

        jsr lcd_printfz
        .asciiz "OK\n"

        jsr APP_START
        jmp @end

    @not_found:
        jsr lcd_printfz
        .asciiz "Not found: "
        lda fat16_ERR
        jsr lcd_printhex
        lda #10
        jsr lcd_printchar
        jmp @end

    @read_failed:
        jsr lcd_printfz
        .asciiz "Read error: "
        lda fat16_ERR
        jsr lcd_printhex
        lda #10
        jsr lcd_printchar

    @end:
        ; TODO: Read result from stack? Is it required? Does the C program return anything?
        ; jsr lcd_clrscr
        ; ldx #0
        ; ldy #3
        ; jsr lcd_gotoxy
        jmp urepl_main

urepl_main:
        jsr lcd_printfz
        .asciiz "MicroREPL READY.\n"

    urepl_loop:
        ; REPL loop
        ; Read
        jsr kbd_getch
        ; Echo
        jsr lcd_printchar
        cmp #10  ; Return pressed
        bne urepl_loop
        lda lcd_BUFFER_PREV
        asl
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp urepl_loop

