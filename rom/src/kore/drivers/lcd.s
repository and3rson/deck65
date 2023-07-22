.include "../../include/define.inc"

.import LCD1_DATA, LCD1_CMD, popa

.export lcd_init = init
.export lcd_printchar = printchar
.export lcd_printhex = printhex
.export lcd_printz = printz
.export lcd_printfz = printfz
.export _puts = printz
.export _cputc = printchar
.export _gotoxy
.export _clrscr = clrscr
.export _printhex = printhex
.export _printword = printword
.export _tgi_getmaxx
.export _tgi_getmaxy

; .export lcd_BUFFER_PREV = BUFFER_PREV

ROWS = 16

.zeropage

PRINT_PTR: .res 2
GOTO_TMP: .res 2
ADDR: .res 2
CX: .res 1
CY: .res 1

.segment "SYSRAM"

BUFFER: .res 40

.segment "KORE"

CHAR_DATA:
    ; $80 - solid block
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    ; $81 - trident
    .byte %00100
    .byte %10101
    .byte %10101
    .byte %11011
    .byte %11111
    .byte %10101
    .byte %11111
    .byte %00100

CHAR_DATA_LEN = * - CHAR_DATA

; Datasheet:
; https://www.sparkfun.com/datasheets/LCD/Monochrome/Datasheet-T6963C.pdf
; Impl:
; https://github.com/zoomx/arduino-t6963c/blob/master/T6963_Lib/T6963.cpp

;;;;;;;;;;;;;;;;;;;;;;;;
; High-level functions

init:
        phx
        phy

        jsr init_device
        jsr clrscr

        ldx #0
        ldy #0
        jsr gotoxy

        ply
        plx

        rts

init_device:
        pha
        phx

        lda #$00
        ldx #$00
        jsr cmd_set_text_home_addr

        lda #$00
        ldx #$20
        jsr cmd_set_graphic_home_addr

        lda #$28  ; 40 columns
        ldx #$00
        jsr cmd_set_text_area

        lda #$28  ; 20 columns
        ldx #$00
        jsr cmd_set_graphic_area

        ; Set mode (OR mode, internal CG)
        lda #$80
        jsr writecmd

        lda #$02
        ldx #$00
        jsr cmd_set_offset_register

        ; Set display mode
        lda #$97  ; text on, graphics off, cursor on, blink on (page 11)
        jsr writecmd

        ; Set cursor pattern
        ; lda #$A0  ; 1-line cursor (page 11)
        lda #$A7  ; 8-line cursor (page 11)
        jsr writecmd

        lda #$00  ; Col (X)
        ldx #$00  ; Row (Y)
        jsr cmd_set_cursor_pos

        ; Write custom characters to CGRAM
        lda #$00
        ldx #$14
        jsr cmd_set_addr_pointer
        jsr cmd_autowrite_on
        ldx #0
    @char_data:
        cpx #CHAR_DATA_LEN
        beq @char_data_done
        lda CHAR_DATA, X
        jsr autowrite
        inx
        jmp @char_data
    @char_data_done:
        jsr cmd_auto_reset

        lda #$00
        ldx #$00
        jsr cmd_set_addr_pointer

        plx
        pla

        rts

clrscr:
        pha
        phx
        phy

        ldx #0
        ldy #0
        jsr gotoxy

        jsr cmd_autowrite_on

        lda #0
        ldy #ROWS
    @again_row:
        ldx #40
    @again_char:
        jsr autowrite
        dex
        bne @again_char
        dey
        bne @again_row

        jsr cmd_auto_reset

        ply
        plx
        pla

        rts

gotoxy:
        pha
        phx
        phy

        stx CX
        sty CY
        stz GOTO_TMP+1

        ; txa
        ; jsr lcd_printhex
        ; tya
        ; jsr lcd_printhex

        ; Set cursor pos
        lda CX  ; X
        ldx CY  ; Y
        ; lda #$00  ; Col (X)
        ; ldx #$00  ; Row (Y)
        jsr writedata2
        lda #$21
        jsr writecmd

        ; Pointer = Y * 40 + X

        ; Old algorithm (8 rows)
        ;
        ; lda CY   ; Y
        ; asl
        ; asl
        ; asl      ; A = Y * 8
        ; sta GOTO_TMP

        ; asl
        ; asl      ; A = Y * 32

        ; clc

        ; adc GOTO_TMP  ; A = Y * 40, possible overflow
        ; sta GOTO_TMP
        ; lda GOTO_TMP+1
        ; adc #0
        ; sta GOTO_TMP+1

        ; lda GOTO_TMP
        ; adc CX   ; A = Y * 40 + X, possible overflow
        ; sta GOTO_TMP
        ; lda GOTO_TMP+1
        ; adc #0
        ; sta GOTO_TMP+1
        ;
        ; Old algorithm end

        ; New algorithm (16 rows)
        ;
        clc
        lda CY
        asl
        asl
        asl            ; A = Y * 8
        sta GOTO_TMP   ; Save Y * 8
        asl
        asl            ; A = Y * 32, possible overflow
        pha            ; Push U * 32

        lda #0
        adc #0
        sta GOTO_TMP+1 ; Carry high
        pla            ; pull Y*8
        adc GOTO_TMP
        sta GOTO_TMP   ; GOTO_TMP = Y * 8 + Y * 32, possible overflow
        lda GOTO_TMP+1
        adc #0
        sta GOTO_TMP+1 ; Carry high

        lda GOTO_TMP
        adc CX         ; A = Y * 40 + X, possible overflow
        sta GOTO_TMP
        lda GOTO_TMP+1
        adc #0
        sta GOTO_TMP+1
        ;
        ; New algorithm end

        ; pha
        ; phx
        ; jsr lcd_printhex
        ; txa
        ; jsr lcd_printhex
        ; plx
        ; pla

        ; Set address pointer (text home address)
        ; lda #$00
        ; ldx #$00
        lda GOTO_TMP
        ldx GOTO_TMP+1
        jsr writedata2
        lda #$24
        jsr writecmd

        ; Set cursor pos
        lda CX
        ldx CY
        jsr cmd_set_cursor_pos

        ply
        plx
        pla

        rts

; Print zero-terminated string that follows jsr which calls this function
;
; Registers:
;   A - not preserved
printfz:
        pla         ; low return PC
        clc
        adc #1      ; first byte after jsr
        sta ADDR
        pla         ; high return PC
        adc #0      ; carry
        sta ADDR+1

        phx         ; preserve X
        tax
        lda ADDR    ; A:X now point to string start
        jsr printz  ; A now contains string length minus one (position of trailing zero byte)
        plx

        ; New return address = ADDR + A (no need to add 1)
        clc
        adc ADDR
        sta ADDR    ; low return PC
        lda ADDR+1
        adc #0
        pha         ; high return PC
        lda ADDR
        pha         ; low return PC

        rts

; Print character to LCD
;
; Arguments:
;   A - character code
printchar:
        pha

        ; Is LF?
        cmp #10
        beq @lf  ; Yes
        ; Is backspace?
        cmp #8
        beq @backspace  ; Yes
        ; Is CR?
        cmp #13
        beq @cr
        ; Is custom character?
        cmp #$80
        bcs @character
        ; code = ASCII - $20 (page 26), but only for <$80
        sec
        sbc #$20

    ; If character:
    @character:
        clc  ; Clearing from possible cmp above... Is this necessary? I'm too tired to decide for now.
        jsr cmd_write_data_increment_adp

        phx
        phy

        ldx CX
        inx
        cpx #40
        bne @move_cursor
        jsr print_crlf
        jmp @no_move_cursor
    @move_cursor:
        ldy CY
        jsr gotoxy

    @no_move_cursor:
        ply
        plx

        jmp @end
    ; If LF:
    @lf:
        jsr print_crlf
        jmp @end
    ; If CR:
    @cr:
        phx
        phy
        ldx #0
        ldy CY
        jsr gotoxy
        ply
        plx
        jmp @end
    ; If backspace:
    @backspace:
        jsr print_backspace

    @end:
        pla

        rts

; Print hexadecimal representation (4-bit)
;
; Arguments:
;   A - value (low nibble)
printnibble:
        pha

        and #$0F
        cmp #10
        bcs @letter ; >= 10

    @digit:
        clc
        adc #48  ; 0..9 -> ascii
        jsr printchar
        jmp @end

    @letter:
        clc
        adc #55  ; 10..15 -> ascii
        jsr printchar

    @end:
        pla

        rts

; Print hexadecimal representation (8-bit)
;
; Arguments:
;   A - value
printhex:
        pha
        phx

        tax
        ; High nibble
        lsr
        lsr
        lsr
        lsr
        jsr printnibble
        txa
        jsr printnibble

        plx
        pla

        rts


; Print hexadecimal representation (16-bit)
;
; Arguments:
;   A:X - value
printword:
        pha

        txa
        jsr printhex
        pla
        jsr printhex

        rts

; __fastcall__ variants
_gotoxy:
        tay  ; 2nd arg
        jsr popa
        tax  ; 1st arg
        jsr gotoxy

        rts

; Print zero-terminated string to LCD
;
; Arguments:
;   A - string addr (low)
;   X - string addr (high)
; Return:
;   A - number of characters printed (i. e. string length)
printz:
        phx
        phy

        sta PRINT_PTR
        stx PRINT_PTR+1

        ldy #0
    @print:
        lda (PRINT_PTR), Y
        beq @end
        jsr printchar
        iny
        jmp @print

        ; jsr cmd_autowrite_on

        ; ldy #0
    ; @print:
        ; lda (PRINT_PTR), Y
        ; beq @end
        ; ; Is CR/LF?
        ; cmp #10
        ; beq @crlf  ; Yes
        ; ; Is backspace?
        ; cmp #8
        ; beq @backspace  ; Yes
        ; ; code = ASCII - $20 (page 26)
        ; sec
        ; sbc #$20

    ; ; If character:
    ; @character:
        ; jsr autowrite
        ; iny
        ; jmp @print
    ; ; If CR/LF:
    ; @crlf:
        ; ; Pause autowrite
        ; jsr cmd_auto_reset
        ; ; Go to next line
        ; jsr print_crlf
        ; ; Resume autowrite
        ; jsr cmd_autowrite_on
        ; iny
        ; jmp @print
    ; @backspace:
        ; jsr cmd_auto_reset
        ; jsr print_backspace
        ; jsr cmd_autowrite_on
        ; iny
        ; jmp @print

    ; @end:
        ; jsr cmd_auto_reset

        ; tya

        ; ; Move cursor
        ; pha
        ; clc
        ; adc CX
        ; tax
        ; ldy CY
        ; jsr gotoxy
        ; pla

    @end:
        tya
        ply
        plx

        rts

print_crlf:
        phx
        phy

        ldx #0
        ldy CY
        iny
        cpy #ROWS
        beq @overflow
        jsr gotoxy
        jmp @end

    @overflow:
        jsr scroll_up

        ldx #0
        ldy #ROWS-1
        jsr gotoxy

    @end:
        ply
        plx

        rts

scroll_up:
        pha
        phx
        phy

        ldy #1
    @copy_row:
        ; Go to row
        ldx #0
        jsr gotoxy

        ; Read row into buffer
        jsr cmd_autoread_on
        ldx #0
    @read_byte:
        jsr autoread
        sta BUFFER, X
        inx
        cpx #40
        bne @read_byte
        jsr cmd_auto_reset

        ; Read row from buffer
        dey
        ldx #0
        jsr gotoxy
        jsr cmd_autowrite_on
    @write_byte:
        lda BUFFER, X
        jsr autowrite
        inx
        cpx #40
        bne @write_byte
        jsr cmd_auto_reset
        iny

        iny
        cpy #ROWS
        bne @copy_row

        ; Clear last row
        ldx #0
        ldy #ROWS-1
        jsr gotoxy
        jsr cmd_autowrite_on
        ldx #0
        lda #0  ; whitespace - $20
    @write_empty:
        jsr autowrite
        inx
        cpx #40
        bne @write_empty
        jsr cmd_auto_reset

        ; Go to last line start
        ldx #0
        ldy #ROWS-1
        jsr gotoxy

        ply
        plx
        pla

        rts

print_backspace:
        pha
        phx
        phy

        ldx CX
        dex
        stx CX
        ldy CY
        jsr gotoxy

        lda #0  ; whitespace - $20
        jsr cmd_write_data_nonvariable_adp

        ply
        plx
        pla

        rts

; unsigned __fastcall__ _tgi_getmaxx(void)
_tgi_getmaxx:
        lda #39
        ldx #0
        rts

; unsigned __fastcall__ _tgi_getmaxy(void)
_tgi_getmaxy:
        lda #ROWS-1
        ldx #0
        rts

;;;;;;;;;;;;;;;;;;;;;;;;
; Low-level interface

; Wait for bits 0 & 1 of status flag
busy:
        pha

    @wait:
        lda LCD1_CMD
        and #3
        cmp #3
        bne @wait

        pla

        rts

; Wait for bit 3 of status flag
autowritebusy:
        pha

    @wait:
        lda LCD1_CMD
        and #8
        cmp #8
        bne @wait

        pla

        rts

; Wait for bit 2 of status flag
autoreadbusy:
        pha

    @wait:
        lda LCD1_CMD
        and #4
        cmp #4
        bne @wait

        pla

        rts

; Write A to data register
writedata:
        jsr busy
        sta LCD1_DATA

        rts

; Write A:X to data register
writedata2:
        jsr busy
        sta LCD1_DATA
        jsr busy
        stx LCD1_DATA

        rts

; Write A to command register
writecmd:
        jsr busy
        sta LCD1_CMD

        rts

; Print character while in auto data write mode
autowrite:
        jsr autowritebusy
        sta LCD1_DATA

        rts

; Read character while in auto data read mode
autoread:
        jsr autoreadbusy
        lda LCD1_DATA

        rts

; Set text home address
cmd_set_text_home_addr:
        pha
        jsr writedata2
        lda #$40
        jsr writecmd
        pla
        rts

; Set graphic home address
cmd_set_graphic_home_addr:
        pha
        jsr writedata2
        lda #$42
        jsr writecmd
        pla
        rts

; Set text area
cmd_set_text_area:
        pha
        jsr writedata2
        lda #$41
        jsr writecmd
        pla
        rts

; Set graphic area
cmd_set_graphic_area:
        pha
        jsr writedata2
        lda #$43
        jsr writecmd
        pla
        rts

; Set offset register
cmd_set_offset_register:
        pha
        jsr writedata2
        lda #$22
        jsr writecmd
        pla
        rts

; Set cursor pos
cmd_set_cursor_pos:
        pha
        jsr writedata2
        lda #$21
        jsr writecmd
        pla
        rts

; Set address pointer (text home address)
cmd_set_addr_pointer:
        pha
        jsr writedata2
        lda #$24
        jsr writecmd
        pla
        rts

; Print character
cmd_write_data_increment_adp:
        pha
        jsr writedata
        lda #$C0
        jsr writecmd
        pla
        rts

; Print character
cmd_write_data_nonvariable_adp:
        pha
        jsr writedata
        lda #$C4
        jsr writecmd
        pla
        rts

; Enable auto-write mode
cmd_autowrite_on:
        pha

        ; Auto data write on
        lda #$B0
        jsr writecmd

        pla
        rts

; Enable auto-read mode
cmd_autoread_on:
        pha

        ; Auto data write on
        lda #$B1
        jsr writecmd

        pla
        rts

; Disable auto-write mode
cmd_auto_reset:
        pha

        ; Auto data write off
        lda #$B2
        jsr writecmd

        pla
        rts


STR: .asciiz "Hello!"
STR2: .asciiz "6502 rocks."

