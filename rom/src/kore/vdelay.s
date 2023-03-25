; vdelay
;
; Authors:
; - Eric Anderson
; - Joel Yliluoma
; - Brad Smith
; - Fiskbit
;
; Version 10
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 29 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X clobbered (X=0)

VDELAY_MINIMUM = 29
VDELAY_FULL_OVERHEAD = 49

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 64

vdelay:                                ; +6 = 6 (jsr)
    cpx #0                             ; +2 = 8 (sets carry)
    BRPAGE bne, vdelay_full            ; +2 = 10
    sbc #VDELAY_MINIMUM+4              ; +2 = 12
    BRPAGE bcc, vdelay_low             ; +2 = 14
vdelay_full_return:
    ; 5-cycle coundown loop + 5 paths   +19 = 33 (carry is set on entry)
@L:        sbc #5
    BRPAGE bcs, @L  ;  6 6 6 6 6  FB FC FD FE FF
           adc #3   ;  2 2 2 2 2  FE FF 00 01 02
    BRPAGE bcc, @4  ;  3 3 2 2 2  FE FF 00 01 02
           lsr      ;  - - 2 2 2  -- -- 00 00 01
    BRPAGE beq, @5  ;  - - 3 3 2  -- -- 00 00 01
@4:        lsr      ;  2 2 - - 2  7F 7F -- -- 00
@5: BRPAGE bcs, @6  ;  2 3 2 3 2  7F 7F 00 00 00
@6:        rts      ;  6 6 6 6 6                 (end >= 33)

; 29-32 cycles handled separately
vdelay_low:                            ; +1 = 15 (bcc)
    adc #3                             ; +2 = 17
    BRPAGE bcc, @0  ;  3 2 2 2  <0 00 01 02
    BRPAGE beq, @0  ;  - 3 2 3  -- 00 01 02
           lsr      ;  - - 2 2  -- -- 00 01
@0: BRPAGE bne, @1  ;  3 2 2 3  <0 00 00 01
@1: rts                                ; +6 = 29 (end < 33)

vdelay_full:                           ; +3 = 11 (carry is set)
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 13
    pha                                ; +3 = 16
    txa                                ; +2 = 18
    sbc #0                             ; +2 = 20
    BRPAGE beq, vdelay_high_none       ; +2 = 22
    : ; 256 cycles each iteration
        ldx #50            ; +2 = 2
        : ; 5 cycle loop   +250 = 252
            dex
            BRPAGE bne, :- ; -1 = 251
        sbc #1             ; +2 = 253 (carry always set)
        BRPAGE bne, :--    ; +3 = 256    -1 = 21 (on last iteration)
    nop                                ; +2 = 23
vdelay_high_none:                      ; +3 = 23 (from branch)
    pla                                ; +4 = 27
    jmp vdelay_full_return             ; +3 = 30 (carry always set)
    ;                                -14+33 = 49
