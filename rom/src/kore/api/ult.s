;
; Ullrich von Bassewitz, 06.08.1998
;
; CC65 runtime: Compare < for unsigned ints
;

.segment "KORE"

        .export         tosult00, tosulta0, tosultax


tosult00        = return0       ; This is always false

tosulta0:
        ldx     #$00
tosultax:
        jsr     tosicmp         ; Set flags
        jmp     boolult         ; Convert to boolean

