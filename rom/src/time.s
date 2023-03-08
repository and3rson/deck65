.code

; Wait for around 300ms (@ 500 KHz)
busywait:
        ldy #$20

    @repeat_out:
        ldx #$20

    @repeat_in:
        dex ; 2 cycles
        bne @repeat_in ; 3-4 cycles
        dey ; 2 cycles
        bne @repeat_out ; 3-4 cycles

        rts
