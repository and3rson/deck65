.feature string_escapes

.import _puts
.import popax

.code

main:
        jsr popax
        lda #<HELLO
        ldx #>HELLO
        jsr _puts
        rts

HELLO: .asciiz "Hello from SD Card!\n"
