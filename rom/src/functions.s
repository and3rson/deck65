.zeropage

F_BYTE: .res 1

.code

; Parse hexadecimal ASCII character into number
; Arguments:
;   A - ASCII character
; Return:
;   A - value (0..15), $F0 if character is not a valid hex literal
f_parse_hex:
        sec
        sbc #'0'
        bmi @invalid  ; Less than 48
        cmp #10
        bmi @end      ; Return digit (== bcc?)

        ; Check for uppercase letter
        sbc #'A'-'0'
        bmi @invalid  ; <A
        cmp #6
        bpl @lowercase  ; >F
        jmp @add10

    @lowercase:
        ; Check for lowercase
        sbc #'a'-'A'
        bmi @invalid  ; <a
        cmp #6
        bpl @invalid  ; >f
        jmp @add10

    @add10:
        clc
        adc #10
        jmp @end
    @invalid:
        lda #$F0
    @end:
        rts

; Parse two hexadecimal ASCII characters into number
; Arguments:
;   X - zeropage address of first of two ASCII characters
; Return:
;   A - value (0..255)
f_parse_octet:
        lda 0, X
        jsr f_parse_hex
        asl
        asl
        asl
        asl
        sta F_BYTE
        lda 1, X
        jsr f_parse_hex
        ora F_BYTE

        rts


; Wait ~8 us
wait8us:
        pha
        phx

        lda #(8 * CYCLES_PER_US)
        ldx #$00
        jsr vdelay

        plx
        pla

        rts


; Wait ~32 us
wait32us:
        pha
        phx

        lda #(32 * CYCLES_PER_US)
        ldx #$00
        jsr vdelay

        plx
        pla

        rts


; Wait ~2 ms
wait2ms:
        pha
        phx

        lda #$00
        ldx #$20
        jsr vdelay

        plx
        pla

        rts


; Wait ~16 ms
wait16ms:
        pha
        phx

        lda #$FF
        ldx #$FF
        jsr vdelay

        plx
        pla

        rts

