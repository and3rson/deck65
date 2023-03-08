; LCD implementation with LF wrapping

.zeropage

; generic 16-bit pointer for string operations
LCD_PTR: .res 2

LCD_CURSOR_X: .res 1
LCD_CURSOR_Y: .res 1
LCD_BUFFER: .res 80

.code

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


; Initialize LCD
; Arguments: none
lcd_init:
        pha
        phx

        lda #0
        sta LCD_CURSOR_X
        sta LCD_CURSOR_Y

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

        lda #%10000000 ; ddgram address set: $00
        sta LCD0
        jsr lcd_busy

    @end:
        plx
        pla

        rts


; Clear LCD
; Arguments: none
lcd_clear:
        pha

        lda #%00000001 ; clear
        sta LCD0
        jsr lcd_busy
        lda #%10000000 ; ddram address set: $00
        sta LCD0
        jsr lcd_busy

        pla

        rts


; Print character to LCD
; Arguments:
;   A - character code
lcd_printchar:
        pha
        phx

        cmp #10
        bne @normal
        ; Fill with spaces
        ldx LCD_CURSOR_X
    @whitespace:
        lda #' '
        sta LCD1
        jsr lcd_busy
        inx
        txa
        cmp #20
        bne @whitespace

        jmp @cr
    @normal:
        ; Print character
        sta LCD1
        jsr lcd_busy

        ; Check cursor X
        ldx LCD_CURSOR_X
        inx
        stx LCD_CURSOR_X
        txa
        ; If not at EOL, end
        cmp #20
        bne @end

    @cr:
        ; Carriage return
        ldx #0
        stx LCD_CURSOR_X

        ; Line feed
        ldx LCD_CURSOR_Y
        inx
        txa
        cmp #4
        bne @savecursor

        ; Wrap cursor to top line
        ldx #0
    @savecursor:
        stx LCD_CURSOR_Y

        ; Update cursor position
        txa
        cmp #1
        beq @gotoline1
        cmp #2
        beq @gotoline2
        cmp #3
        beq @gotoline3

    @gotoline0:
        ; Y=0: ADD=0
        lda #0
        jmp @writeline

    @gotoline1:
        ; Y=1: 64
        lda #64
        jmp @writeline

    @gotoline2:
        ; Y=2: 20
        lda #20
        jmp @writeline

    @gotoline3:
        ; Y=3: 84
        lda #84

    @writeline:
        ; Write new position to DDRAM
        ora #%10000000
        sta LCD0

    @end:
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

        ldx #0

    @printchar:
        lda (LCD_PTR), Y
        cmp #0
        beq @end

        jsr lcd_printchar
        iny
        jmp @printchar

    @end:
        ply
        plx
        pla

        rts

