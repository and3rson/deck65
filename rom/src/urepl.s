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

.code

S_READY: .asciiz "MicroREPL READY\n"
S_LOADING: .asciiz "Loading song...\n"
S_INITIALIZING: .asciiz "Initializing...\n"
S_STARTING: .asciiz "Starting...\n"
S_UNKNOWN_COMMAND: .asciiz "Unknown cmd: "
S_NOT_FOUND: .asciiz "Not found: "
S_READ_ERROR: .asciiz "Read err: "
S_JMP: .asciiz "JMP: "
S_PROGRESS: .asciiz ".\n"

cmd_noop:
        jmp cmd_done


cmd_err:
        print S_UNKNOWN_COMMAND
        a8call lcd::printchar, lcd::BUFFER_40
        a8call lcd::printchar, #' '
        a8call lcd::printchar, #'('
        a8call lcd::printhex, lcd::BUFFER_40
        a8call lcd::printchar, #')'
        a8call lcd::printchar, #10
        jmp cmd_done


cmd_printmem:
        ldx #lcd::BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        a8call lcd::printhex, PTR+1
        a8call lcd::printhex, PTR
        a8call lcd::printchar, #':'
        a8call lcd::printchar, #' '

        ldy #0
    @rep:
        lda (PTR), Y
        jsr lcd::printhex
        a8call lcd::printchar, #' '
        iny
        cpy #4
        bne @rep
        a8call lcd::printchar, #10

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

        print S_JMP
        a8call lcd::printhex, PTR+1
        a8call lcd::printhex, PTR
        a8call lcd::printchar, #10

        jmp (PTR)


cmd_find:
        lda #<(lcd::BUFFER_40+1)
        ldx #>(lcd::BUFFER_40+1)
        jsr fat16::open
        bcs @not_found
        a8call lcd::printhex, fat16::F_SIZE+3
        a8call lcd::printhex, fat16::F_SIZE+2
        a8call lcd::printhex, fat16::F_SIZE+1
        a8call lcd::printhex, fat16::F_SIZE
        a8call lcd::printchar, #10
        jmp @end

    @not_found:
        print S_NOT_FOUND
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
        print S_NOT_FOUND
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar
        jmp @end

    @read_failed:
        print S_READ_ERROR
        lda fat16::ERR
        jsr lcd::printhex
        lda #10
        jsr lcd::printchar

    @end:
        jmp cmd_done

repl_main:
        print S_READY

    repl_loop:
        ; REPL loop
        ; Read
        jsr kbd::getch
        ; Echo
        jsr lcd::printchar
        cmp #10  ; Return pressed
        bne repl_loop
        lda lcd::BUFFER_40
        clc
        adc lcd::BUFFER_40
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp repl_loop

