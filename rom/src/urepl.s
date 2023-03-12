.zeropage

PTR: .res 2

.code

S_READY: .asciiz "MicroREPL READY\n"
S_LOADING: .asciiz "Loading song...\n"
S_INITIALIZING: .asciiz "Initializing...\n"
S_STARTING: .asciiz "Starting...\n"
S_UNKNOWN_COMMAND: .asciiz "Unknown cmd: "
S_JMP: .asciiz "JMP: "
S_PROGRESS: .asciiz ".\n"

.align $100
CMD_JUMPTABLE:
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err
    .word cmd_noop, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_printmem
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_jmp, cmd_err, cmd_err, cmd_printmem, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err


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
        ldx #4
    @read:
        lda LCD_BUFFER_40, X
        jsr f_parse_hex
        ; TODO: Error checking
        and #$0F
        pha
        dex
        bne @read

        ; Top of stack is high nibble of high byte
        pla
        asl
        asl
        asl
        asl
        sta PTR+1
        pla
        ora PTR+1
        sta PTR+1

        ; Top of stack is high nibble of low byte
        pla
        asl
        asl
        asl
        asl
        sta PTR
        pla
        ora PTR
        sta PTR

        a8call lcd_printhex, PTR+1
        a8call lcd_printhex, PTR
        a8call lcd_printchar, #':'
        a8call lcd_printchar, #' '
        ; a8call lcd_printhex, (PTR)
        ; a8call lcd_printchar, #'('
        ; a8call lcd_printchar, (PTR)
        ; a8call lcd_printchar, #')'
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


cmd_jmp:
        ldx #4
    @read:
        lda LCD_BUFFER_40, X
        jsr f_parse_hex
        ; TODO: Error checking
        and #$0F
        pha
        dex
        bne @read

        ; Top of stack is high nibble of high byte
        pla
        asl
        asl
        asl
        asl
        sta PTR+1
        pla
        ora PTR+1
        sta PTR+1

        ; Top of stack is high nibble of low byte
        pla
        asl
        asl
        asl
        asl
        sta PTR
        pla
        ora PTR
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

