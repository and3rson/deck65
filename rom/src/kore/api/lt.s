;
; Ullrich von Bassewitz, 06.08.1998
;
; CC65 runtime: Compare < for signed ints
;

.segment "KORE"

        .export         toslt00, toslta0, tosltax

toslt00:
        lda     #$00
toslta0:
        ldx     #$00
tosltax:
        jsr     tosicmp         ; Set flags
        jmp     boollt          ; Convert to boolean

