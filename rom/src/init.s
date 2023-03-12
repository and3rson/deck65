.zeropage

PTR: .res 2

.code

S_BAR19: .asciiz "===================\n"
S_HELLO: .asciiz "Hi there!\n"
S_SYSTEM: .asciiz "64K RAM SYSTEM\n"
S_READY: .asciiz "READE\x08YX\x08\n"
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
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_printmem, cmd_err, cmd_err
    .word cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err, cmd_err

cmd_noop:
        jmp cmd_done

cmd_err:
        lda #<S_UNKNOWN_COMMAND
        ldx #>S_UNKNOWN_COMMAND
        jsr lcd_printz
        lda LCD_BUFFER_40
        jsr lcd_printchar
        lda #' '
        jsr lcd_printchar
        lda #'('
        jsr lcd_printchar
        lda LCD_BUFFER_40
        jsr lcd_printhex
        lda #')'
        jsr lcd_printchar
        lda #10
        jsr lcd_printchar
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

        lda PTR+1
        jsr lcd_printhex
        lda PTR
        jsr lcd_printhex
        lda #'='
        jsr lcd_printchar
        lda (PTR)
        jsr lcd_printhex
        lda #' '
        jsr lcd_printchar
        lda #'('
        jsr lcd_printchar
        lda (PTR)
        jsr lcd_printchar
        lda #')'
        jsr lcd_printchar
        lda #10
        jsr lcd_printchar

        jmp cmd_done

        ; ldx #1
        ; lda LCD_BUFFER_40, X
        ; jsr f_parse_hex
        ; jsr lcd_printhex
        ; ldx #2
        ; lda LCD_BUFFER_40, X
        ; jsr f_parse_hex
        ; jsr lcd_printhex
        ; ldx #3
        ; lda LCD_BUFFER_40, X
        ; jsr f_parse_hex
        ; jsr lcd_printhex
        ; ldx #4
        ; lda LCD_BUFFER_40, X
        ; jsr f_parse_hex
        ; jsr lcd_printhex
        ; jmp cmd_done


; Kernel entrypoint
; Arguments: none
init:
        sei
        jsr interrupts_init
        jsr kbd_init
        jsr lcd_init
        cli

        lda #<S_BAR19
        ldx #>S_BAR19
        jsr lcd_printz

        lda #<S_HELLO
        ldx #>S_HELLO
        jsr lcd_printz

        lda #<S_SYSTEM
        ldx #>S_SYSTEM
        jsr lcd_printz

        lda #<S_READY
        ldx #>S_READY
        jsr lcd_printz

    ; REPL loop
    loop:
        ; Read
        jsr kbd_getch
        ; Echo
        jsr lcd_printchar
        cmp #10  ; Return pressed
        bne loop
        ; Parse command
        ; lda #<S_JMP
        ; ldx #>S_JMP
        ; jsr lcd_printz
        ; lda #>CMD_JUMPTABLE
        ; sta PTR+1
        ; jsr lcd_printhex
        ; lda LCD_BUFFER_40
        ; asl A
        ; sta PTR
        ; jsr lcd_printhex
        ; ; lda #10
        ; ; jsr lcd_printchar
        ; jmp PTR
        lda LCD_BUFFER_40
        clc
        adc LCD_BUFFER_40
        tax
        jmp (CMD_JUMPTABLE, X)
    cmd_done:
        jmp loop

        ; load song into RAM
        ; ldy #0
    ; @copy_byte:
        ; lda songdata,Y
        ; sta songdest,Y
        ; lda PTR
        ; inc
        ; sta PTR
        ; iny
        ; cpy #songlen
        ; bne @copy_byte

        ; lda #<S_INITIALIZING
        ; ldx #>S_INITIALIZING
        ; jsr lcd_printz

        ; ; init song
        ; jsr songinit

        ; lda #<S_STARTING
        ; ldx #>S_STARTING
        ; jsr lcd_printz

    ; @play:
        ; ; play song
        ; jsr songplay

        ; lda #<S_PROGRESS
        ; ldx #>S_PROGRESS
        ; jsr lcd_printz

        ; jmp @play

        ; lda LCD0 ; for debug
        stp

    songstart:
; .incbin "./music/mca_vrolijke_vier.sid"
; this currently works only for songs <256 bytes
.incbin "./music/Crue_Gurl_Freestyle_Remix.sid"
; .incbin "./music/Room_2.sid"
    songend:

    songdata = songstart + $7E
    songlen = songend - songdata
    ; songdest = $0FFF
    songdest = $1000
    songinit = $1006
    songplay = $1000
    ; songdest = $10EB
    ; songinit = $10EB
    ; songplay = $1102

    .byte $AA, $BB
    foo1: .byte >songstart
    foo2: .byte <songstart
    foo3: .byte >songdata
    foo4: .byte <songdata

; TODO: Basic basic
; TODO: LOAD from SD card
