.feature string_escapes

.import popax, lcd_printfz, lcd_printhex
.importzp ptr1, tmp1, tmp2

.code

DATA = $D200
CMD  = $D201

; Datasheet:
; https://www.sparkfun.com/datasheets/LCD/Monochrome/Datasheet-T6963C.pdf
; Impl:
; https://github.com/zoomx/arduino-t6963c/blob/master/T6963_Lib/T6963.cpp

; int __cdecl__ main(int argc, char **argv)
main:
        jsr popax  ; Pop **argv
        jsr popax  ; Pop argc

        jsr lcd_printfz
        .asciiz "init\n"
        jsr init
        jsr lcd_printfz
        .asciiz "clrscr\n"
        jsr clrscr

        jsr lcd_printfz
        .asciiz "gotoxy\n"
        ldx #0
        ldy #0
        jsr gotoxy

        jsr lcd_printfz
        .asciiz "puts\n"
        lda #<STR
        ldx #>STR
        jsr puts

        jsr lcd_printfz
        .asciiz "gotoxy\n"
        ldx #15
        ldy #5
        jsr gotoxy

        jsr lcd_printfz
        .asciiz "puts\n"
        lda #<STR2
        ldx #>STR2
        jsr puts

        jsr lcd_printfz
        .asciiz "gotoxy\n"
        ldx #39
        ldy #7
        jsr gotoxy

        lda #0  ; Return 0
        ldx #0

        rts

;;;;;;;;;;;;;;;;;;;;;;;;
; High-level functions

init:
        pha
        phx

        ; Set text home address
        lda #$00
        ldx #$00
        jsr writedata2
        lda #$40
        jsr writecmd

        ; Set graphic home address
        lda #$00
        ldx #$20
        jsr writedata2
        lda #$42
        jsr writecmd

        ; Set text area
        lda #$28  ; 40 columns
        ldx #$00
        jsr writedata2
        lda #$41
        jsr writecmd

        ; Set graphic area
        lda #$28  ; 20 columns
        ldx #$00
        jsr writedata2
        lda #$43
        jsr writecmd

        ; Set mode (OR mode, internal CG)
        lda #$80
        jsr writecmd

        ; Set offset register
        lda #$02
        ldx #$00
        jsr writedata2
        lda #$22
        jsr writecmd

        ; Set display mode
        lda #$97  ; text on, graphics off, cursor on, blink on (page 11)
        jsr writecmd

        ; Set cursor pattern
        lda #$A0  ; 1-line cursor (page 11)
        jsr writecmd

        ; Set cursor pos
        lda #$00  ; Col (X)
        ldx #$00  ; Row (Y)
        jsr writedata2
        lda #$21
        jsr writecmd

        ; Set address pointer (text home address)
        lda #$00
        ldx #$00
        jsr writedata2
        lda #$24
        jsr writecmd

        plx
        pla

        rts

clrscr:
        pha
        phx

        ldx #0
        ldy #0
        jsr gotoxy

        jsr autowrite_on

        lda #0
        ldx #0
    @again:
        jsr autowrite
        inx
        ; 256 iterations
        bne @again

        ldx #64
    @again2:
        jsr autowrite
        dex
        ; 64 iterations
        bne @again2

        jsr autowrite_off

        plx
        pla

        rts

gotoxy:
        pha
        phy
        phx

        stx tmp1
        sty tmp2

        ; txa
        ; jsr lcd_printhex
        ; tya
        ; jsr lcd_printhex

        ; Set cursor pos
        lda tmp1  ; X
        ldx tmp2  ; Y
        ; lda #$00  ; Col (X)
        ; ldx #$00  ; Row (Y)
        jsr writedata2
        lda #$21
        jsr writecmd

        ; Pointer = Y * 40 + X

        lda tmp2  ; Y
        asl
        asl
        asl       ; A = Y * 8
        sta tmp2

        asl
        asl       ; A = Y * 32

        clc
        adc tmp2  ; A = Y * 40
        adc tmp1  ; A = Y * 40 + X
        sta tmp2
        lda #0
        adc #0
        tax       ; High byte
        lda tmp2  ; Low byte

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
        jsr writedata2
        lda #$24
        jsr writecmd

        plx
        ply
        pla
        rts

autowrite_on:
        pha

        ; Auto data write on
        lda #$B0
        jsr writecmd

        pla
        rts

autowrite_off:
        pha

        ; Auto data write off
        lda #$B2
        jsr writecmd

        pla
        rts

; A:X - zero-terminated string address
puts:
        pha
        phy

        sta ptr1
        stx ptr1+1

        jsr autowrite_on

        ldy #0
    @print:
        lda (ptr1), Y
        beq @end
        sec
        ; code = ASCII - $20 (page 26)
        sbc #$20
        jsr autowrite
        iny
        jmp @print

    @end:
        jsr autowrite_off

        ply
        pla
        rts

;;;;;;;;;;;;;;;;;;;;;;;;
; Low-level functions

; Wait for bits 0 & 1 of status flag
busy:
        pha

    @wait:
        lda CMD
        and #3
        cmp #3
        bne @wait

        pla

        rts

; Wait for bit 3 of status flag
autowritebusy:
        pha

    @wait:
        lda CMD
        and #8
        cmp #8
        bne @wait

        pla

        rts

; Write A:X to data register
writedata2:
        jsr busy
        sta DATA
        jsr busy
        stx DATA

        rts

; Write A to command register
writecmd:
        jsr busy
        sta CMD

        rts

; Print character while in auto data write mode
autowrite:
        jsr autowritebusy
        sta DATA

        rts

STR: .asciiz "Hello!"
STR2: .asciiz "6502 rocks."
