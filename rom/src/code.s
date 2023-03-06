.segment "CODE"

S_HELLO: .byte "Hello there!\n\x00"
S_SYSTEM: .byte "64K RAM SYSTEM\n\x00"
S_READY: .byte "READY\n\x00"

; Wait until LCD is ready
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
lcd_init:
        pha
        phx

        lda #0
        sta CURSORX
        sta CURSORY

        ldx #$04
    @repeat:
        lda #%10101010 ; digital analyzer trigger

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
; A - character code
lcd_printchar:
        pha
        phx

        cmp #10
        bne @normal
        ; Fill with spaces
        ldx CURSORX
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
        ldx CURSORX
        inx
        stx CURSORX
        txa
        ; If not at EOL, end
        cmp #20
        bne @end

    @cr:
        ; Carriage return
        ldx #0
        stx CURSORX

        ; Line feed
        ldx CURSORY
        inx
        txa
        cmp #4
        bne @savecursor

        ; Wrap cursor to top line
        ldx #0
    @savecursor:
        stx CURSORY

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
; A - lower addr
; X - higher addr
lcd_printz:
        pha
        phx
        phy

        ; Store string start address to PTR
        sta PTR
        stx PTR+1

        ldx #0

    @printchar:
        lda (PTR), Y
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

; .export _main
; _main:
init:
    jsr lcd_init
    jsr lcd_clear

    lda #<S_HELLO
    ldx #>S_HELLO
    jsr lcd_printz

    lda #<S_SYSTEM
    ldx #>S_SYSTEM
    jsr lcd_printz

    lda #<S_READY
    ldx #>S_READY
    jsr lcd_printz

    lda LCD0 ; for debug
    stp
