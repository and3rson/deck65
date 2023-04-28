.feature string_escapes

.import _puts

.code

main:
        lda #<HELLO
        ldx #>HELLO
        jsr _puts
        rts

HELLO: .asciiz "Hello from SD Card!\n"
