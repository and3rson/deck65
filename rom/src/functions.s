.code

; Parse hexadecimal ASCII character into number
; Arguments:
;   A - ASCII character
; Return:
;   A - value (0..15), $FF if character is not a valid hex literal
f_parse_hex:
        sec
        sbc #'0'
        bmi @invalid  ; Less than 48
        cmp #10
        bmi @end      ; Return digit (== bcc?)

        ; Check for letter
        sbc #'A'-'0'
        bmi @invalid  ; <A
        cmp #6
        bpl @invalid  ; >F
        clc
        adc #10
        jmp @end

    @invalid:
        lda #$FF
    @end:
        rts
