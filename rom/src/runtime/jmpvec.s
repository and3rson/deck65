.export jmpvec, init_jmpvec

.bss

jmpvec: .res 3  ; Reserved for "jmp $FFFF"

.code

init_jmpvec:
    lda #$4C  ; "jmp" opcode
    sta jmpvec
    rts
