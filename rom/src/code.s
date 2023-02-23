.segment "ZP"

.res 3           ;6510 register area
COLOR: .res 1
CODE: .res 1

.segment "CODE"

init:
    ; TODO: C64 only
    sei
    stx $d016
    jsr $fda3           ; prepare IRQ
    jsr $fd50           ; init memory. Rewrite this routine to speed up boot process.
    jsr $fd15           ; init I/O
    jsr $ff5b           ; init video

    ; lda #$42
    lda #$03 ; color
    sta COLOR
    lda #$0D ; code
    sta CODE
    cli

@rep:
    lda COLOR
    sta $D800
    adc 1
    sta $D801
    adc 1
    sta $D802
    adc 1
    sta $D803
    adc 1
    sta $D804
    ; adc 1
    ; sta $D827
    ; adc 1
    ; sta $D828
    ; adc 1
    ; sta $D829
    ; adc 1
    ; sta $D82A
    ; adc 1
    ; sta $D82B
    ; adc 1
    ; sta $D82C
    ; adc 1
    ; sta $D82D

    lda CODE
    sta $0400
    sta $0401
    sta $0402
    sta $0403
    sta $0404
    ; ina
    tax
    ; inx
    txa
    cmp $1A
    bne @save

    lda #$01 ; reset CODE

@save:
    sta CODE
    jmp @rep
