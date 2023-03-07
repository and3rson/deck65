.segment "CODE"

S_HELLO: .byte "Hello there!\n\x00"
S_SYSTEM: .byte "64K RAM SYSTEM\n\x00"
S_READY: .byte "READY\n\x00"


; Kernel entrypoint
; Arguments: none
init:
    jsr lcd_init
    jsr lcd_clear

    lda #<S_HELLO
    ldx #>S_HELLO
    jsr lcd_printz

    jsr busywait

    lda #<S_SYSTEM
    ldx #>S_SYSTEM
    jsr lcd_printz

    jsr busywait

    lda #<S_READY
    ldx #>S_READY
    jsr lcd_printz

; TODO: Load this at 0FFF
; .incbin "./music/mca_vrolijke_vier.sid"

; TODO: Basic basic
; TODO: LOAD from SD card

    lda LCD0 ; for debug
    stp
