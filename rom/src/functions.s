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
