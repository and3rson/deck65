;
; Ullrich von Bassewitz, 31.08.1998
;
; CC65 runtime: Load ax from offset in stack
;

.segment "KORE"

        .export         ldax0sp, ldaxysp

; Beware: The optimizer knows about the value in Y after return!

ldax0sp:
        ldy     #1
ldaxysp:
        lda     (sp),y          ; get high byte
        tax                     ; and save it
        dey                     ; point to lo byte
        lda     (sp),y          ; load low byte
        rts

