.code

irq:
        pha
        lda #$11
        lda #$22
        pla
        rti

nmi:
        pha
        lda #$33
        lda #$44
        pla
        rti
