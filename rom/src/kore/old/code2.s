.segment "CODE"

MSG: .byte "Foo bar\n"

.import _write, _read, _exit, _fputs, pushax

.export _main
_main:
init:
    sei
    ; lda 42
    ; sta V0
    cli

rep:
    ; lda _stdout
    ; ldx _stdout+1
    lda #1
    ldx #0
    jsr pushax

    lda #<MSG
    ldx #>MSG
    jsr pushax

    lda #8
    ldx #0

    ; jsr _write
    jsr _write

    ; jmp rep
    lda #$69
    jmp _exit
