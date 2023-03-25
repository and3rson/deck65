.segment "CODE"

.export _main
_main:
init:
    ; sei
    ; lda 42
    ; sta V0
    ; cli

rep:
    lda #$22
    sta V0
    lda #$66
    adc V0
    sta V1
    jmp rep
