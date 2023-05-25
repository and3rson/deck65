;
; Interrupt routines (mostly for VIA)
;

.import lcd_printfz
.import kbd_process
.import uart_process
.import VIA1_RA
.import VIA1_RB
.import VIA1_IFR
.import ACIA1_DATA
.import ACIA1_STAT

.export irq
.export nmi

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

        ; Notify about ISR start
        lda #$80
        sta VIA1_RA

        ; ****************
        ; Check VIA interrupts
        ; ****************
        lda VIA1_IFR
        ; Clear all interrupt flags
        ldx #$7F
        stx VIA1_IFR

        and #%00001000  ; Is CB2? (PS/2 keyboard)
        ; and #%00000001  ; Is CA2? (PS/2 keyboard)
        beq @via_end
        lda VIA1_RB
        ; rol
        ; rol
        ror
        ror
        ror
        ror
        and #1
        jsr kbd_process
    @via_end:

        ; ****************
        ; Check ACIA interrupts
        ; ****************
        lda ACIA1_STAT
        rol
        bcc @acia_end
        lda ACIA1_DATA
        jsr uart_process
    @acia_end:

        stz VIA1_RA

        plx
        pla
        rti

nmi:
        jsr lcd_printfz
        .asciiz "NMI!"
        ; pha
        ; lda #$33
        ; lda #$44
        ; pla
        rti
