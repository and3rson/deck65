.code

S_INTERRUPT: .asciiz "INT!\n"

interrupts_init:
        phx

        ; ****************
        ; VIA - Common
        ; ****************
        ; Don't let T1 toggle PB7, PA, or PB latch
        ; lda VIA1_ACR
        ; and #$7C
        stz VIA1_ACR
        ; Keyboard interrupts with CB2
        lda VIA1_PCR
        ; ora #%00100000  ; CB2 - Independent interrupt input-negative edge (page 13)
        ora #%00000010  ; CA2 - Independent interrupt input-negative edge (page 13)
        ; and #%00011111  ; CB2 - Input-negative active edge (page 13)
        sta VIA1_PCR
        ; Enable interrupts for keyboard only
        lda #%01111111  ; Disable all interrupts
        sta VIA1_IER
        ; lda #%10001000  ; Set interrupt flag for CB2 (page 27)
        lda #%10000001  ; Set interrupt flag for CA2 (page 27)
        sta VIA1_IER

        ; ****************
        ; VIA - Port A
        ; ****************
        ; PS/2 Keyboard
        ;   CB2 - Clock
        ;   PA7      - data
        ; LCD
        ;   PA6      - RS
        ;   PA5      - R/W
        ;   PA4      - EN
        ;   PA3..PA0 - data
        lda #%10100000
        sta VIA1_RA
        lda #$FF
        sta VIA1_DDRA

        ; ****************
        ; VIA - Port B
        ; ****************
        ; PS/2 Keyboard
        ;   CB2 - Clock
        ;   PB0 - Data
        ; lda VIA1_DDRB
        ; and #%11111110  ; PB0 as input
        ; sta VIA1_DDRB

        ; ****************
        ; VIA - Clear all interrupt flags
        ; ****************
        lda #$7F
        sta VIA1_IFR

        plx

        rts

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
        jsr kbd_process

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
