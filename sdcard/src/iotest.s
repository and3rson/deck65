.feature string_escapes

.import popax

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

        ; Set address pointer (text home address)
        lda #$00
        ldx #$00
        jsr writedata2
        lda #$24
        jsr writecmd

        ; Set cursor pos
        lda #$00  ; Col (X)
        ldx #$00  ; Row (Y)
        jsr writedata2
        lda #$21
        jsr writecmd

        ; Set cursor pattern
        lda #$A0  ; 1-line cursor (page 11)
        jsr writecmd

        ; Auto data write on
        lda #$B0
        jsr writecmd

        ; Write "Hello" (page 26)
        lda #$28
        jsr autowrite
        lda #$45
        jsr autowrite
        lda #$4C
        jsr autowrite
        lda #$4C
        jsr autowrite
        lda #$4F
        jsr autowrite

        ; Auto data write off
        lda #$B2
        jsr writecmd

        lda #0  ; Return 0
        ldx #0

        rts

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
