;
; Ullrich von Bassewitz, 25.10.2000
;
; CC65 runtime: Increment the stackpointer by 3
;

.segment "KORE"

        .export         incsp3

.proc   incsp3

        ldy     #3
        jmp     addysp

.endproc





