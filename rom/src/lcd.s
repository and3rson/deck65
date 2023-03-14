;
; HD44780 20x04 LCD implementation with constant tty-like scrolling
;
; Uses 6522 VIA w/ 4-bit data bus & busy flag polling
; https://www.sparkfun.com/datasheets/LCD/HD44780.pdf
;

.scope lcd

.zeropage

; generic 16-bit pointer for string operations
PTR:   .res  2
REG:   .res  2
MEM:   .res  2
INIT:  .res  1  ; Set to $01 if LCD was initialized in one of previous boots

RS  =  %01000000
RW  =  %00100000
EN  =  %00010000

CURSOR_X:  .res  1
CURSOR_Y:  .res  1
BUFFER:    .res  80
BUFFER_20  =  BUFFER + 20
BUFFER_40  =  BUFFER + 40
BUFFER_60  =  BUFFER + 60

P_DD_LINE_ADDR: .res 2

.code

; The code below was tested at 4 MHz, but it should run on any frequency
; as long as CLOCK is set to a proper value.

DD_LINE_ADDR: .byte 0, 64, 20, 84

; Initialize LCD
init:
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
        sta BUFFER, X
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

        ; lda INIT  ; Is LCD already initialized?
        ; bne @postinit
        ; inc
        ; sta INIT

    @init:
        ; https://www.microchip.com/forums/m/tm.aspx?m=1023133&p=1
        ; ldy #$40  ; 1 s
        ldy #$10  ; 256ms
    @longinit:
        lda #$FF
        ldx #$FF
        jsr vdelay  ; 16.384 ms
        dey
        bne @longinit

        ; Initialize 4-bit mode
        lda #%0010
        jsr writenib
        lda #$00
        ldx #$40
        jsr vdelay  ; 4 ms

        lda #%0010
        jsr writenib
        lda #$00
        ldx #$02
        jsr vdelay  ; 128 us

        lda #%0010
        jsr writenib
        lda #$00
        ldx #$01
        jsr vdelay  ; 64 us

    @postinit:
        lda #%00101000  ; 4 bit, 2 lines, 5x8
        jsr writecmd
        jsr busy

        lda #%00000110  ; increment, no shift
        jsr writecmd
        jsr busy

        lda #%00001111  ; display on, cursor on, blink on
        jsr writecmd
        jsr busy

        lda #%00000001  ; Clear screen
        jsr writecmd
        jsr busy
        lda #$00
        ldx #$40
        jsr vdelay  ; 4 ms

        ldx #0
        ldy #3
        jsr gotoxy

    @end:
        ply
        plx
        pla

        rts

; Write nibble with EN toggle
;
; Arguments:
;   A - nibble with register bit (%0x00xxxx)
writenib:
        pha
        phx

        ldx #$7F
        stx VIA1_DDRA

        tax
        ; Assert RS
        and #RS
        sta VIA1_RA
        jsr wait8us
        txa

        ; Assert data
        sta VIA1_RA
        jsr wait32us

        ; Assert E=1
        eor #EN
        sta VIA1_RA
        jsr wait8us

        ; Assert E=0
        eor #EN
        sta VIA1_RA
        jsr wait8us

        plx
        pla

        rts

; Write cmd byte with EN toggle
;
; Arguments:
;   A - byte
writecmd:
        pha

        ; Write high nibble
        lsr
        lsr
        lsr
        lsr
        jsr writenib

        ; Write low nibble
        pla
        and #$0F
        jsr writenib

        rts

; Write data byte with EN toggle
;
; Arguments:
;   A - byte
writedata:
        pha

        ; Write high nibble
        lsr
        lsr
        lsr
        lsr
        ora #RS
        jsr writenib

        ; Write low nibble
        pla
        and #$0F
        ora #RS
        jsr writenib

        rts

; Read byte with EN toggle
;
; Return:
;   A - value
read_clock:
        ; Set data to input
        phx

        lda #$70
        sta VIA1_DDRA

        ldx #2
    @next:
        lda #RW  ; RS=0, RW=1, EN=0
        sta VIA1_RA
        jsr wait8us
        eor #EN  ; EN=1
        sta VIA1_RA
        jsr wait8us
        lda VIA1_RA  ; read nibble
        and #$0F
        sta MEM - 1, X
        lda #RW  ; RS=0, RW=1, EN=0
        sta VIA1_RA
        jsr wait8us
        dex
        bne @next

        ; MEM[0, 1] = low, high
        lda MEM+1
        asl
        asl
        asl
        asl
        ora MEM

        plx

        rts


; Block while LCD is busy
busy:
        pha

    @check:
        jsr read_clock
        and #$80
        bne @check

        pla

        rts


; Move LCD cursor
;
; Arguments:
;   X - column
;   Y - row
gotoxy:
        pha
        phx
        phy

        stx CURSOR_X
        sty CURSOR_Y
        ; Get DDRAM addr for line start
        lda (P_DD_LINE_ADDR), Y
        ; Add X
        clc
        adc CURSOR_X
        ; Add instruction flag
        ora #$80
        ; Move cursor
        jsr writecmd
        jsr busy

    @end:
        ply
        plx
        pla

        rts



; ; Clear LCD
; ; Arguments: none
; clear:
;         pha
;         phx
;         phy

;         lda #%00000001 ; clear
;         jsr write_cmd

;         ; Set cursor pos
;         ldx #0
;         ldy #3
;         jsr gotoxy

;         ply
;         plx
;         pla

;         rts


; Print character to LCD
; Do not print anything if no space is left
;
; Arguments:
;   A - character code
printchar:
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
        lda CURSOR_X
        cmp #19
        beq @end  ; no more space

        ; Print character
        pha
        txa
        jsr writedata
        jsr busy
        pla

        ; Char X-pos -> X, char code -> A
        phx
        tax
        pla

        ; Write to screen buffer
        sta BUFFER_60, X

        ; Increase cursor X-pos
        inx
        stx CURSOR_X

        jmp @end

    @newline:
        ; Scroll screen memory up by 20 bytes
        ldx #0
    @scroll1:
        lda BUFFER_20, X
        sta BUFFER, X
        inx
        cpx #60
        bne @scroll1

        ; Fill line 3 with spaces
        ldx #0
    @add_space:
        lda #' '
        sta BUFFER_60, X
        inx
        cpx #20
        bne @add_space

        jsr redraw

        ldx #0
        ldy #3
        jsr gotoxy

        jmp @end

    @backspace:
        lda CURSOR_X
        beq @end  ; already at first column
        ; Update cursor position & screen buffer
        tax
        dex
        stx CURSOR_X
        lda #' '
        sta BUFFER_60, X
        ; Move cursor left
        lda #%00010000
        jsr writecmd
        jsr busy
        ; Write space
        lda #' '
        jsr writedata
        jsr busy
        ; Move cursor left
        lda #%00010000
        jsr writecmd
        jsr busy

    @end:
        ply
        plx
        pla

        rts

; Redraw entire screen from memory buffer
redraw:
        pha
        phx
        phy

        ldx #0
        ldy #0
        jsr gotoxy
    @print_line0:
        lda BUFFER, X
        jsr writedata
        jsr busy
        inx
        cpx #20
        bne @print_line0

        ldx #0
        ldy #1
        jsr gotoxy
    @print_line1:
        lda BUFFER_20, X
        jsr writedata
        jsr busy
        inx
        cpx #20
        bne @print_line1

        ldx #0
        ldy #2
        jsr gotoxy
    @print_line2:
        lda BUFFER_40, X
        jsr writedata
        jsr busy
        inx
        cpx #19
        bne @print_line2

        ldx #0
        ldy #3
        jsr gotoxy
    @print_line3:
        lda BUFFER_60, X
        jsr writedata
        jsr busy
        inx
        cpx #19
        bne @print_line3

        ply
        plx
        pla

        rts


; Print zero-terminated string to LCD
;
; Arguments:
;   A - string addr (low)
;   X - string addr (high)
printz:
        pha
        phx
        phy

        ; Store string start address to PTR
        sta PTR
        stx PTR+1

        ldy #0

    @printchar:
        lda (PTR), Y
        ; cmp #0
        beq @end

        jsr printchar
        iny
        jmp @printchar

    @end:
        ply
        plx
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

; Print binary representation
;
; Arguments:
;   A - value
printbin:
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
        jsr printchar
        tya
        rol
        tay
        dex
        bne @again

        ply
        plx
        pla

        rts

crlf:
        pha

        lda #10
        jsr printchar

        pla

        rts
.endscope
