.segment "ZEROPAGE"

PTR: .res 2

.segment "CODE"

S_BAR19: .byte "===================\n\x00"
S_HELLO: .byte "Hello there!\n\x00"
S_SYSTEM: .byte "64K RAM SYSTEM\n\x00"
S_READY: .byte "READE\x08YX\x08\n\x00"
S_LOADING: .byte "Loading song...\n\x00"
S_INITIALIZING: .byte "Initializing...\n\x00"
S_STARTING: .byte "Starting...\n\x00"
S_PROGRESS: .byte ".\n\x00"


; Kernel entrypoint
; Arguments: none
init:
        lda #%10101010 ; digital analyzer trigger

        jsr lcd_init

        ; ldx #8
        ; ldy #2
        ; jsr lcd_gotoxy

        lda #<S_BAR19
        ldx #>S_BAR19
        jsr lcd_printz

        lda #<S_HELLO
        ldx #>S_HELLO
        jsr lcd_printz

        ; jsr busywait

        lda #<S_SYSTEM
        ldx #>S_SYSTEM
        jsr lcd_printz

        ; ; ; jsr busywait

        lda #<S_READY
        ldx #>S_READY
        jsr lcd_printz

        ; print VIA values
        ; lda VIA1_SR
        ; jsr lcd_printhex
        ; lda VIA1_ACR
        ; jsr lcd_printhex
        ; lda VIA1_PCR
        ; jsr lcd_printhex
        ; lda VIA1_IFR
        ; jsr lcd_printhex
        ; lda VIA1_EFR
        ; jsr lcd_printhex
        ; lda VIA1_EFR
        ; jsr lcd_printhex
        ; lda #' '
        ; jsr lcd_printchar

        lda #%10101100
        jsr lcd_printbin
        lda #' '
        jsr lcd_printchar
        lda #%01010011
        jsr lcd_printbin

        ; Bit-bang all bits of VIA (port B)
        ; lda #$FF
        ; sta VIA1_DDRB
        ; sta VIA1_RB
    ; @flip:
        ; inc VIA1_RB
        ; dec VIA1_RB
        ; inx
        ; dex
        ; jmp @flip

        ; lda #<S_LOADING
        ; ldx #>S_LOADING
        ; jsr lcd_printz

    ; @tmp:
    ;     lda #15
    ;     sta $D418
    ;     lda #<S_PROGRESS
    ;     ldx #>S_PROGRESS
    ;     jsr lcd_printz
    ;     lda #0
    ;     sta $D418
    ;     lda #<S_PROGRESS
    ;     ldx #>S_PROGRESS
    ;     jsr lcd_printz
    ;     jmp @tmp

        ; load song into RAM
        ; ldy #0
    ; @copy_byte:
        ; lda songdata,Y
        ; sta songdest,Y
        ; lda PTR
        ; inc
        ; sta PTR
        ; iny
        ; cpy #songlen
        ; bne @copy_byte

        ; lda #<S_INITIALIZING
        ; ldx #>S_INITIALIZING
        ; jsr lcd_printz

        ; ; init song
        ; jsr songinit

        ; lda #<S_STARTING
        ; ldx #>S_STARTING
        ; jsr lcd_printz

    ; @play:
        ; ; play song
        ; jsr songplay

        ; lda #<S_PROGRESS
        ; ldx #>S_PROGRESS
        ; jsr lcd_printz

        ; jmp @play

        lda LCD0 ; for debug
        stp

    songstart:
; .incbin "./music/mca_vrolijke_vier.sid"
; this currently works only for songs <256 bytes
.incbin "./music/Crue_Gurl_Freestyle_Remix.sid"
; .incbin "./music/Room_2.sid"
    songend:

    songdata = songstart + $7E
    songlen = songend - songdata
    ; songdest = $0FFF
    songdest = $1000
    songinit = $1006
    songplay = $1000
    ; songdest = $10EB
    ; songinit = $10EB
    ; songplay = $1102

    .byte $AA, $BB
    foo1: .byte >songstart
    foo2: .byte <songstart
    foo3: .byte >songdata
    foo4: .byte <songdata

; TODO: Basic basic
; TODO: LOAD from SD card
