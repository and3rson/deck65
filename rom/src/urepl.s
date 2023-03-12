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
    jmptbl 'j', cmd_jmp
    jmptbl 'm', cmd_printmem

.code

S_READY: .asciiz "MicroREPL READY\n"
S_LOADING: .asciiz "Loading song...\n"
S_INITIALIZING: .asciiz "Initializing...\n"
S_STARTING: .asciiz "Starting...\n"
S_UNKNOWN_COMMAND: .asciiz "Unknown cmd: "
S_JMP: .asciiz "JMP: "
S_PROGRESS: .asciiz ".\n"

cmd_noop:
        jmp cmd_done


cmd_err:
        print S_UNKNOWN_COMMAND
        a8call lcd_printchar, LCD_BUFFER_40
        a8call lcd_printchar, #' '
        a8call lcd_printchar, #'('
        a8call lcd_printhex, LCD_BUFFER_40
        a8call lcd_printchar, #')'
        a8call lcd_printchar, #10
        jmp cmd_done


cmd_printmem:
        ldx #LCD_BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        a8call lcd_printhex, PTR+1
        a8call lcd_printhex, PTR
        a8call lcd_printchar, #':'
        a8call lcd_printchar, #' '

        ldy #0
    @rep:
        lda (PTR), Y
        jsr lcd_printhex
        a8call lcd_printchar, #' '
        iny
        cpy #4
        bne @rep
        a8call lcd_printchar, #10

        jmp cmd_done


cmd_writemem:
        ldx #LCD_BUFFER_40+1
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
        ldx #LCD_BUFFER_40+1
        jsr f_parse_octet
        sta PTR+1

        inx
        inx
        jsr f_parse_octet
        sta PTR

        print S_JMP
        a8call lcd_printhex, PTR+1
        a8call lcd_printhex, PTR
        a8call lcd_printchar, #10

        jmp (PTR)


repl_main:
        print S_READY

    repl_loop:
        ; REPL loop
        ; Read
        jsr kbd_getch
        ; Echo
        jsr lcd_printchar
        cmp #10  ; Return pressed
        bne repl_loop
        lda LCD_BUFFER_40
        clc
        adc LCD_BUFFER_40
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp repl_loop

