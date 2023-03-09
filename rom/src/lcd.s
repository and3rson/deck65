; LCD implementation with constant tty-like scrolling

.zeropage

; generic 16-bit pointer for string operations
LCD_PTR: .res 2

LCD_CURSOR_X: .res 1
LCD_CURSOR_Y: .res 1
LCD_BUFFER: .res 80
LCD_BUFFER_20 = LCD_BUFFER + 20
LCD_BUFFER_40 = LCD_BUFFER + 40
LCD_BUFFER_60 = LCD_BUFFER + 60

P_DD_LINE_ADDR: .res 2

.code

DD_LINE_ADDR: .byte 0, 64, 20, 84

; Wait until LCD is ready
; Arguments: none
lcd_busy:
        pha
    @wait:
        lda LCD0
        and #%10000000
        bne @wait
    @end:
        pla

        rts


; Move LCD cursor
; Arguments:
;   X - column
;   Y - row
lcd_gotoxy:
        pha
        phx
        phy

        stx LCD_CURSOR_X
        sty LCD_CURSOR_Y
        ; Get DDRAM addr for line start
        lda (P_DD_LINE_ADDR), Y
        ; Add X
        clc
        adc LCD_CURSOR_X
        ; Add instruction flag
        ora #$80
        ; Move cursor
        sta LCD0
        jsr lcd_busy

    @end:
        ply
        plx
        pla

        rts

; Initialize LCD
; Arguments: none
lcd_init:
        pha
        phx
        phy

        ; Set up pointer to array with line addresses
        lda #<DD_LINE_ADDR
        sta P_DD_LINE_ADDR
        lda #>DD_LINE_ADDR
        sta P_DD_LINE_ADDR+1

        ; Clear screen buffer
    @clear:
        lda #' '
        sta LCD_BUFFER, X
        inx
        cpx #80
        bne @clear

        ldx #$04
    @repeat:
        lda #%00111000 ; 8 bit, 2 lines, 5x8
        sta LCD0
        jsr lcd_busy

        dex
        bne @repeat

        lda #%00000110 ; increment, no shift
        sta LCD0
        jsr lcd_busy

        lda #%00001111 ; display on, cursor on, blink on
        sta LCD0
        jsr lcd_busy

        ; lda #%10000000 ; ddgram address set: $00
        ; lda #(DD_LINE_ADDR | %10000000) ; ddram address set: line 3 start
        ; sta LCD0
        ; jsr lcd_busy

        ; Clear screen
        jsr lcd_clear

    @end:
        ply
        plx
        pla

        rts


; Clear LCD
; Arguments: none
lcd_clear:
        pha
        phx
        phy

        lda #%00000001 ; clear
        sta LCD0
        jsr lcd_busy

        ; Set cursor pos
        ldx #0
        ldy #3
        jsr lcd_gotoxy

        ply
        plx
        pla

        rts


; Print character to LCD
; Do not print anything if no space is left
; Arguments:
;   A - character code
lcd_printchar:
        pha
        phx
        phy

        ; Check if \n
        cmp #10
        beq @newline

        cmp #8
        beq @backspace

        ; Check if has space
        tax
        lda LCD_CURSOR_X
        cmp #19
        beq @end  ; no more space

        ; Print character
        stx LCD1
        jsr lcd_busy

        ; Char X-pos -> X, char code -> A
        phx
        tax
        pla

        ; Write to screen buffer
        sta LCD_BUFFER_60, X

        ; Increase cursor X-pos
        inx
        stx LCD_CURSOR_X

        jmp @end

    @newline:
        ; Scroll screen memory up by 20 bytes
        ldx #0
    @scroll1:
        lda LCD_BUFFER_20, X
        sta LCD_BUFFER, X
        inx
        cpx #60
        bne @scroll1

        ; Fill line 3 with spaces
        ldx #0
    @add_space:
        lda #' '
        sta LCD_BUFFER_60, X
        inx
        cpx #20
        bne @add_space

        jsr lcd_redraw

        ldx #0
        ldy #3
        jsr lcd_gotoxy

        jmp @end

    @backspace:
        lda LCD_CURSOR_X
        beq @end  ; already at first column
        ; Update cursor position & screen buffer
        tax
        dex
        stx LCD_CURSOR_X
        lda #' '
        sta LCD_BUFFER_60, X
        ; Move cursor left
        lda #%00010000
        sta LCD0
        jsr lcd_busy
        ; Write space
        lda #' '
        sta LCD1
        jsr lcd_busy
        ; Move cursor left
        lda #%00010000
        sta LCD0
        jsr lcd_busy

    @end:
        ply
        plx
        pla

        rts

; Redraw entire screen from memory buffer
lcd_redraw:
        pha
        phx
        phy

        ldx #0
        ldy #0
        jsr lcd_gotoxy
    @print_line0:
        lda LCD_BUFFER, X
        sta LCD1
        jsr lcd_busy
        inx
        cpx #20
        bne @print_line0

        ldx #0
        ldy #1
        jsr lcd_gotoxy
    @print_line1:
        lda LCD_BUFFER_20, X
        sta LCD1
        jsr lcd_busy
        inx
        cpx #20
        bne @print_line1

        ldx #0
        ldy #2
        jsr lcd_gotoxy
    @print_line2:
        lda LCD_BUFFER_40, X
        sta LCD1
        jsr lcd_busy
        inx
        cpx #19
        bne @print_line2

        ldx #0
        ldy #3
        jsr lcd_gotoxy
    @print_line3:
        lda LCD_BUFFER_60, X
        sta LCD1
        jsr lcd_busy
        inx
        cpx #19
        bne @print_line3

        ply
        plx
        pla

        rts


; Print zero-terminated string to LCD
; Arguments:
;   A - string addr (low)
;   X - string addr (high)
lcd_printz:
        pha
        phx
        phy

        ; Store string start address to PTR
        sta LCD_PTR
        stx LCD_PTR+1

        ldy #0

    @printchar:
        lda (LCD_PTR), Y
        ; cmp #0
        beq @end

        jsr lcd_printchar
        iny
        jmp @printchar

    @end:
        ply
        plx
        pla

        rts

; Print hexadecimal representation (4-bit)
; Arguments:
;   A - value (low nibble)
lcd_printnibble:
        pha

        and #$0F
        cmp #$0A
        bcs @letter ; >= 10

    @digit:
        clc
        adc #48  ; 0..9 -> ascii
        jsr lcd_printchar
        jmp @end

    @letter:
        clc
        adc #55  ; 10..15 -> ascii
        jsr lcd_printchar

    @end:
        pla

        rts

; Print hexadecimal representation (8-bit)
; Arguments:
;   A - value
lcd_printhex:
        pha
        phx

        tax
        ; High nibble
        lsr
        lsr
        lsr
        lsr
        jsr lcd_printnibble
        txa
        jsr lcd_printnibble

        plx
        pla

        rts

; Print binary representation
; Arguments:
;   A - value
lcd_printbin:
        pha
        phx
        phy

        ldx #8
        tay
    @again:
        tya  ; restore A & set sign bit
        bmi @one
    @zero:
        lda #'0'
        jmp @print
    @one:
        lda #'1'
    @print:
        jsr lcd_printchar
        tya
        rol
        tay
        dex
        bne @again

        ply
        plx
        pla

        rts
