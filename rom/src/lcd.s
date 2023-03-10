; LCD implementation with constant tty-like scrolling
; Uses 6522 VIA w/ 4-bit data bus & busy flag polling

.zeropage

; generic 16-bit pointer for string operations
LCD_PTR: .res 2
LCD_REG: .res 2
LCD_MEM: .res 2
LCD_INIT: .res 1  ; Set to $01 if LCD was initialized in one of previous boots

LCD_RS = %01000000
LCD_RW = %00100000
LCD_EN = %00010000

LCD_CURSOR_X: .res 1
LCD_CURSOR_Y: .res 1
LCD_BUFFER: .res 80
LCD_BUFFER_20 = LCD_BUFFER + 20
LCD_BUFFER_40 = LCD_BUFFER + 40
LCD_BUFFER_60 = LCD_BUFFER + 60

P_DD_LINE_ADDR: .res 2

.code

; The code below is timed to work at 4 MHz

DD_LINE_ADDR: .byte 0, 64, 20, 84

; Wait >32 cycles (>8 us @ 4 MHz)
lcd_wait32c:
        pha
        phx

        lda #$20
        ldx #$00
        jsr vdelay

        plx
        pla

        rts

; Wait >128 cycles (>32 us @ 4 MHz)
lcd_wait128c:
        pha
        phx

        lda #$80
        ldx #$00
        jsr vdelay

        plx
        pla

        rts

; Write nibble with EN toggle
; Arguments:
;   A - nibble with register bit (%0x00xxxx)
lcd_writenib:
        pha
        phx

        ldx #$FF
        stx VIA1_DDRA

        tax
        ; Assert RS
        and #LCD_RS
        sta VIA1_RA
        jsr lcd_wait32c
        txa

        ; Assert data
        sta VIA1_RA
        jsr lcd_wait128c

        ; Assert E=1
        eor #LCD_EN
        sta VIA1_RA
        jsr lcd_wait32c

        ; Assert E=0
        eor #LCD_EN
        sta VIA1_RA
        jsr lcd_wait32c

        plx
        pla

        rts

; Write cmd byte with EN toggle
; Arguments:
;   A - byte
lcd_writecmd:
        pha

        ; Write high nibble
        lsr
        lsr
        lsr
        lsr
        jsr lcd_writenib

        ; Write low nibble
        pla
        and #$0F
        jsr lcd_writenib

        rts

; Write data byte with EN toggle
; Arguments:
;   A - byte
lcd_writedata:
        pha

        ; Write high nibble
        lsr
        lsr
        lsr
        lsr
        ora #LCD_RS
        jsr lcd_writenib

        ; Write low nibble
        pla
        and #$0F
        ora #LCD_RS
        jsr lcd_writenib

        rts

; Read byte with EN toggle
; Return:
;   A - value
lcd_read_clock:
        ; Set data to input
        phx

        lda #$F0
        sta VIA1_DDRA

        ldx #2
    @next:
        lda #LCD_RW  ; RS=0, RW=1, EN=0
        sta VIA1_RA
        jsr lcd_wait32c
        ; jsr lcd_busywait
        eor #LCD_EN  ; EN=1
        sta VIA1_RA
        ; jsr lcd_busywait
        jsr lcd_wait32c
        lda VIA1_RA  ; read nibble
        and #$0F
        sta LCD_MEM - 1, X
        lda #LCD_RW  ; RS=0, RW=1, EN=0
        sta VIA1_RA
        jsr lcd_wait32c
        dex
        bne @next

        ; LCD_MEM[0, 1] = low, high
        lda LCD_MEM+1
        asl
        asl
        asl
        asl
        ora LCD_MEM

        plx

        rts


; Block while LCD is busy
lcd_busy:
        pha

    @check:
        jsr lcd_read_clock
        and #$80
        bne @check

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
        jsr lcd_writecmd
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

        ; Init VIA
        ; Bits:
        ; 7    - n/c
        ; 6    - RS
        ; 5    - R/W
        ; 4    - EN
        ; 3..0 - data
        lda #%00100000
        sta VIA1_RA
        lda #$FF
        sta VIA1_DDRA

        ; Don't let T1 toggle PB7, PA, or PB latch
        lda VIA1_ACR
        and #$7C
        sta VIA1_ACR

        ; Clear screen buffer
    @clear:
        lda #' '
        sta LCD_BUFFER, X
        inx
        cpx #80
        bne @clear

        ; vdelay @ 4 MHz:
        ; $0020 - 8 us
        ; $0080 - 32 us
        ; $0100 - 64 us
        ; $0200 - 128 us
        ; $1000 - 1.024 ms
        ; $4000 - 4.096 ms
        ; $FFFF - ~16.384 ms

        ; lda LCD_INIT  ; Is LCD already initialized?
        ; bne @postinit
        ; inc
        ; sta LCD_INIT

    @init:
        ; https://www.microchip.com/forums/m/tm.aspx?m=1023133&p=1
        ; ldy #$40  ; 1 s
        ldy #$4  ; 64ms
    @longinit:
        lda #$FF
        ldx #$FF
        jsr vdelay  ; 16.384 ms
        dey
        bne @longinit

        ; Initialize 4-bit mode
        lda #%0010
        jsr lcd_writenib
        lda #$00
        ldx #$40
        jsr vdelay  ; 4 ms

        lda #%0010
        jsr lcd_writenib
        lda #$00
        ldx #$02
        jsr vdelay  ; 128 us

        lda #%0010
        jsr lcd_writenib
        lda #$00
        ldx #$01
        jsr vdelay  ; 64 us

    @postinit:
        lda #%00101000  ; 4 bit, 2 lines, 5x8
        jsr lcd_writecmd
        jsr lcd_busy

        lda #%00000110  ; increment, no shift
        jsr lcd_writecmd
        jsr lcd_busy

        lda #%00001111  ; display on, cursor on, blink on
        jsr lcd_writecmd
        jsr lcd_busy

        lda #%00000001  ; Clear screen
        jsr lcd_writecmd
        jsr lcd_busy
        lda #$00
        ldx #$40
        jsr vdelay  ; 4 ms

        ldx #0
        ldy #3
        jsr lcd_gotoxy

    @end:
        ply
        plx
        pla

        rts


; ; Clear LCD
; ; Arguments: none
; lcd_clear:
;         pha
;         phx
;         phy

;         lda #%00000001 ; clear
;         jsr lcd_write_cmd

;         ; Set cursor pos
;         ldx #0
;         ldy #3
;         jsr lcd_gotoxy

;         ply
;         plx
;         pla

;         rts


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
        pha
        txa
        jsr lcd_writedata
        jsr lcd_busy
        pla

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
        jsr lcd_writecmd
        jsr lcd_busy
        ; Write space
        lda #' '
        jsr lcd_writedata
        jsr lcd_busy
        ; Move cursor left
        lda #%00010000
        jsr lcd_writecmd
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
        jsr lcd_writedata
        jsr lcd_busy
        inx
        cpx #20
        bne @print_line0

        ldx #0
        ldy #1
        jsr lcd_gotoxy
    @print_line1:
        lda LCD_BUFFER_20, X
        jsr lcd_writedata
        jsr lcd_busy
        inx
        cpx #20
        bne @print_line1

        ldx #0
        ldy #2
        jsr lcd_gotoxy
    @print_line2:
        lda LCD_BUFFER_40, X
        jsr lcd_writedata
        jsr lcd_busy
        inx
        cpx #19
        bne @print_line2

        ldx #0
        ldy #3
        jsr lcd_gotoxy
    @print_line3:
        lda LCD_BUFFER_60, X
        jsr lcd_writedata
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
