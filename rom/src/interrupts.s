.code

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
        plx
        pla
        rti

nmi:
        pha
        lda #$33
        lda #$44
        pla
        rti
