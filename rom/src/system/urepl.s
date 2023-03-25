;
; Simple interactive REPL shell & memory monitor
;

.zeropage

PTR: .res 2
DAT: .res 1

.segment "JMPTABLE"

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

.segment "RAM"

APP_START = $1000

.segment "SYSTEM"

cmd_noop:
        jmp cmd_done


cmd_err:
        jsr lcd::printfz
        .asciiz "Unknown cmd: "
        acall lcd::printchar, lcd::BUFFER_40
        acall lcd::printchar, #' '
        acall lcd::printchar, #'('
        acall lcd::printhex, lcd::BUFFER_40
        acall lcd::printchar, #')'
        acall lcd::printchar, #10
        jmp cmd_done


cmd_printmem:
        ldx #lcd::BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        acall lcd::printhex, PTR+1
        acall lcd::printhex, PTR
        acall lcd::printchar, #':'
        acall lcd::printchar, #' '

        ldy #0
    @rep:
        lda (PTR), Y
        jsr lcd::printhex
        acall lcd::printchar, #' '
        iny
        cpy #4
        bne @rep
        acall lcd::printchar, #10

        jmp cmd_done


cmd_writemem:
        ldx #lcd::BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        inx
        inx
        inx
        jsr f_parse_octet

        sta (PTR)

        jmp cmd_done


cmd_jmp:
        ldx #lcd::BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        jsr lcd::printfz
        .asciiz "JMP to: "
        acall lcd::printhex, PTR+1
        acall lcd::printhex, PTR
        acall lcd::printchar, #10

        jmp (PTR)


cmd_find:
        lda #<(lcd::BUFFER_40+1)
        ldx #>(lcd::BUFFER_40+1)
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
        lda #<(lcd::BUFFER_40+1)
        ldx #>(lcd::BUFFER_40+1)
        jsr fat16::open
        bcs @not_found

        lda #<APP_START
        ldx #>APP_START
        jsr fat16::read
        bcs @read_failed

        jsr APP_START
        jmp @end

    @not_found:
        jsr lcd::printfz
        .asciiz "Not fnd: "
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar
        jmp @end

    @read_failed:
        jsr lcd::printfz
        .asciiz "Read err: "
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar

    @end:
        jmp cmd_done

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
        lda lcd::BUFFER_40
        clc
        adc lcd::BUFFER_40
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp urepl_loop

