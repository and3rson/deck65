.feature string_escapes

.import _puts
.import popax
.import lcd_printfz
.import lcd_printhex
.import lcd_printchar

.code

DATA = $D200
CMD  = $D201

; Datasheet:
; https://www.sparkfun.com/datasheets/LCD/Monochrome/Datasheet-T6963C.pdf
;
; Impl:
; https://github.com/zoomx/arduino-t6963c/blob/master/T6963_Lib/T6963.cpp

main:
        jsr popax
        ; jsr lcd_printfz
        ; .asciiz "24064 status: "
        ; lda CMD  ; Load status
        ; jsr lcd_printhex
        ; lda #10
        ; jsr lcd_printchar

        jsr lcd_printfz
        .asciiz "Set text home addr\n"
        ; Set text home address
        lda #$00
        ldx #$00
        jsr writedata2
        lda #$40
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set graphic home addr\n"
        ; Set graphic home address
        lda #$00
        ldx #$20
        jsr writedata2
        lda #$42
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set text area\n"
        ; Set text area
        lda #$28  ; 40 columns
        ldx #$00
        jsr writedata2
        lda #$41
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set graphic area\n"
        ; Set graphic area
        lda #$28  ; 20 columns
        ldx #$00
        jsr writedata2
        lda #$43
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Mode set\n"
        ; Set mode (OR mode, internal CG)
        lda #$80
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set offset register\n"
        ; Set offset register
        lda #$02
        ldx #$00
        jsr writedata2
        lda #$22
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set display mode\n"
        ; Set display mode
        lda #$97  ; text on, graphics off, cursor on, blink on (page 11)
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set address pointer\n"
        ; Set address pointer (text home address)
        lda #$00
        ldx #$00
        jsr writedata2
        lda #$24
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set cursor pos\n"
        ; Set cursor pos
        lda #$00  ; Col (X)
        ldx #$00  ; Row (Y)
        jsr writedata2
        lda #$21
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Set cursor pattern\n"
        ; Set cursor pattern
        lda #$A0  ; 1-line cursor (page 11)
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Auto data write on\n"
        ; Auto data write on
        lda #$B0
        jsr writecmd

        ; ; Write blank code
        ; lda 'W'
        ; jsr autowrite

        ldx #25
    @clear:
        lda #$00
        jsr autowrite
        dex
        bne @clear

        jsr lcd_printfz
        .asciiz "Auto data write off\n"
        ; Auto data write off
        lda #$B2
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Auto data write on\n"
        ; Auto data write on
        lda #$B0
        jsr writecmd

        jsr lcd_printfz
        .asciiz "Write text\n"
        ; Write "Hello" (page 26)
        ; lda #$28
        lda #$27
        jsr autowrite
        lda #$45
        jsr autowrite
        lda #$4C
        jsr autowrite
        lda #$4C
        jsr autowrite
        lda #$4F
        jsr autowrite
        ; lda #'H'  ; Char
        ; jsr writedata2
        ; lda #$C0  ; Data write, increment ADP
        ; jsr writecmd
        ; lda #'e'  ; Char
        ; jsr writedata2
        ; lda #$C0  ; Data write, increment ADP
        ; jsr writecmd
        ; lda #'l'  ; Char
        ; jsr writedata2
        ; lda #$C0  ; Data write, increment ADP
        ; jsr writecmd
        ; lda #'l'  ; Char
        ; jsr writedata2
        ; lda #$C0  ; Data write, increment ADP
        ; jsr writecmd
        ; lda #'o'  ; Char
        ; jsr writedata2
        ; lda #$C0  ; Data write, increment ADP
        ; jsr writecmd

        jsr lcd_printfz
        .asciiz "Auto data write off\n"
        ; Auto data write off
        lda #$B2
        jsr writecmd

        rts

busy:
        pha

    @wait:
        lda CMD
        jsr lcd_printhex
        and #3
        cmp #3
        bne @wait

        pla

        rts

autowritebusy:
        pha

    @wait:
        lda CMD
        jsr lcd_printhex
        and #8
        cmp #8
        bne @wait

        pla

        rts

writedata2:
        jsr busy
        sta DATA
        jsr busy
        stx DATA

        rts

writecmd:
        jsr busy
        sta CMD

        rts

autowrite:
        jsr autowritebusy
        sta DATA

        rts

HELLO: .asciiz "Hello from SD Card!\n"
