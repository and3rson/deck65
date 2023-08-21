.zeropage

PREV_BANK: .res 1

.segment "KORE"

.macro enter_kernelspace
        ; ldy BANK
        stz BANK
        ; phy
.endmacro

.macro exit_kernelspace
        ; ply
        ; sty BANK
.endmacro
