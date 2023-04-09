;
; Ullrich von Bassewitz, 25.10.2000
;
; CC65 runtime: Increment the stackpointer by 4
;
.segment "KORE"

        .export         incsp4

.proc   incsp4

        ldy     #4
        jmp     addysp

.endproc





