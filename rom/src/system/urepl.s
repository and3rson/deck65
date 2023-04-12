;
; Simple interactive REPL shell & memory monitor
;

.zeropage

PTR: .res 2
DAT: .res 1

.segment "RAM"

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
        jsr lcd::printfz
        .asciiz "Unknown cmd: "
        acall lcd::printchar, lcd::BUFFER_PREV
        acall lcd::printchar, #' '
        acall lcd::printchar, #'('
        acall lcd::printhex, lcd::BUFFER_PREV
        acall lcd::printchar, #')'
        acall lcd::printchar, #10
        jmp cmd_done


cmd_printmem:
        lda #<(lcd::BUFFER_PREV+1)
        ldx #>(lcd::BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd::BUFFER_PREV+3)
        ldx #>(lcd::BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        acall lcd::printhex, PTR+1
        acall lcd::printhex, PTR
        acall lcd::printchar, #':'

        ldy #0
    @rep1:
        lda (PTR), Y
        jsr lcd::printhex
        acall lcd::printchar, #' '
        iny
        cpy #8
        bne @rep1

        acall lcd::printchar, #'['

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
        jsr lcd::printchar
        iny
        cpy #8
        bne @rep2

        acall lcd::printchar, #']'
        acall lcd::printchar, #10

        jmp cmd_done


cmd_writemem:
        lda #<(lcd::BUFFER_PREV+1)
        ldx #>(lcd::BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd::BUFFER_PREV+3)
        ldx #>(lcd::BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        lda #<(lcd::BUFFER_PREV+6)
        ldx #>(lcd::BUFFER_PREV+6)
        jsr f_parse_octet

        sta (PTR)

        jmp cmd_done


cmd_jmp:
        lda #<(lcd::BUFFER_PREV+1)
        ldx #>(lcd::BUFFER_PREV+1)
        jsr f_parse_octet
        sta PTR+1

        lda #<(lcd::BUFFER_PREV+3)
        ldx #>(lcd::BUFFER_PREV+3)
        jsr f_parse_octet
        sta PTR

        jsr lcd::printfz
        .asciiz "JMP to: "
        acall lcd::printhex, PTR+1
        acall lcd::printhex, PTR
        acall lcd::printchar, #10

        jmp (PTR)


cmd_find:
        lda #<(lcd::BUFFER_PREV+1)
        ldx #>(lcd::BUFFER_PREV+1)
        jsr fat16::open
        bcs @not_found
        acall lcd::printhex, fat16::F_SIZE+3
        acall lcd::printhex, fat16::F_SIZE+2
        acall lcd::printhex, fat16::F_SIZE+1
        acall lcd::printhex, fat16::F_SIZE
        acall lcd::printchar, #10
        jmp @end

    @not_found:
        jsr lcd::printfz
        .asciiz "Not found: "
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar

    @end:
        jmp cmd_done

cmd_run:
        lda #<(lcd::BUFFER_PREV+1)
        ldx #>(lcd::BUFFER_PREV+1)
        jsr fat16::open
        bcs @not_found

        lda #<APP_START
        sta PTR
        lda #>APP_START
        sta PTR+1
    @read:

        ;
        ; lda fat16::F_CLU
        ; jsr lcd::printhex
        ; lda fat16::F_CLU+1
        ; jsr lcd::printhex
        lda #'.'
        jsr lcd::printchar
        ;

        lda PTR
        ldx PTR+1
        jsr fat16::read
        bcs @read_failed
        cmp #1  ; has more data
        bne @done
        clc
        lda PTR+1
        adc #2
        sta PTR+1
        jmp @read
    @done:

        jsr lcd::printfz
        .asciiz "!"

        jsr APP_START
        jmp @end

    @not_found:
        jsr lcd::printfz
        .asciiz "Not found: "
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar
        jmp @end

    @read_failed:
        jsr lcd::printfz
        .asciiz "Read error: "
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar

    @end:
        ; TODO: Read result from stack? Is it required? Does the C program return anything?
        ; jsr lcd::clrscr
        ; ldx #0
        ; ldy #3
        ; jsr lcd::gotoxy
        jmp urepl_main

urepl_main:
        jsr lcd::printfz
        .asciiz "MicroREPL READY.\n"

    urepl_loop:
        ; REPL loop
        ; Read
        jsr kbd::getch
        ; Echo
        jsr lcd::printchar
        cmp #10  ; Return pressed
        bne urepl_loop
        lda lcd::BUFFER_PREV
        asl
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp urepl_loop

