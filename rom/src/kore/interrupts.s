;
; Interrupt routines (mostly for VIA)
;

.segment "KORE"

S_INTERRUPT: .asciiz "INT!\n"

irq:
        pha
        phx
        ; lda #<S_INTERRUPT
        ; ldx #>S_INTERRUPT
        ; jsr lcd_printz
        ; ; Clear VIA timer1 interrupt flag
        ; ; lda VIA1_IFR
        ; lda VIA1_T1CL

        lda VIA1_IFR
        ; and #%00001000  ; Is CB2? (PS/2 keyboard)
        and #%00000001  ; Is CA2? (PS/2 keyboard)
        beq @end
        lda VIA1_RA
        rol
        rol
        and #1
        jsr kbd::process

    @end:
        ; Clear all interrupt flags
        lda #$7F
        sta VIA1_IFR

        plx
        pla
        rti

nmi:
        pha
        lda #$33
        lda #$44
        pla
        rti
