.org $1000

lcd_printz = $E250

main:
        lda #<HELLO
        ldx #>HELLO
        jsr lcd_printz
        rts

HELLO: .asciiz "Hello!"
