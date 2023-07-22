.feature string_escapes
.import _printf, pushax, _puts

.export _main
_main:
        lda #39
        sta CX
        lda #15
        sta CY

        lda #0
        sta GOTO_TMP+1
        phx
        plx

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

        lda #<STR
        ldx #>STR
        jsr pushax
        lda GOTO_TMP
        ldx GOTO_TMP+1
        ; lda #$34
        ; ldx #$12
        jsr pushax
        ldy #4
        jsr _printf

        lda #0
        ldx #0
        rts

GOTO_TMP: .res 2
CX: .res 1
CY: .res 1

STR: .asciiz "Foo bar: $%04x\n"
