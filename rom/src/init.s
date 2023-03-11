.segment "ZEROPAGE"

PTR: .res 2

.segment "CODE"

S_BAR19: .asciiz "===================\n"
S_HELLO: .asciiz "Hi there!\n"
S_SYSTEM: .asciiz "64K RAM SYSTEM\n"
S_READY: .asciiz "READE\x08YX\x08\n"
S_LOADING: .asciiz "Loading song...\n"
S_INITIALIZING: .asciiz "Initializing...\n"
S_STARTING: .asciiz "Starting...\n"
S_PROGRESS: .asciiz ".\n"


; Kernel entrypoint
; Arguments: none
init:
        sei
        jsr interrupts_init
        jsr kbd_init
        jsr lcd_init
        cli

        lda #<S_BAR19
        ldx #>S_BAR19
        jsr lcd_printz

        lda #<S_HELLO
        ldx #>S_HELLO
        jsr lcd_printz

        lda #<S_SYSTEM
        ldx #>S_SYSTEM
        jsr lcd_printz

        lda #<S_READY
        ldx #>S_READY
        jsr lcd_printz

    ; REPL loop
    @loop:
        jsr kbd_getch
        jsr lcd_printchar
        cmp #10  ; Return pressed
        bne @loop
        ; TODO: Execute command
        jmp @loop

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

        ; lda LCD0 ; for debug
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
