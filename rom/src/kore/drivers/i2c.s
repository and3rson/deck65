;
; I2C bus implementation

.import wait8us
.import VIA1_DDRB
.import VIA1_RB

SDA = %00100000
SCL = %01000000

.export _i2c_start = start
.export _i2c_stop = stop
.export _i2c_write
.export _i2c_read
.export i2c_init = init

.zeropage

.segment "KORE"

; Initialize bus
init:
        rts

; Start transaction
start:
        pha

        ; Start condition
        jsr _scl_release
        jsr _sda_assert
        jsr _scl_assert

        pla

        rts

; Stop transaction
stop:
        pha

        jsr _sda_assert
        jsr _scl_release
        jsr _sda_release

        pla

        rts

; Write byte and read ACK bit
;
; Arguments:
;   A - address or data
; Return:
;   C - set if not acked
write:
        pha
        phx

        ; Write 8 bits (addr + R/W)
        clc
        ldx #8
    @write:
        rol
        bcs @one
        jsr _sda_assert  ; Send 0
        jmp @done
    @one:
        jsr _sda_release  ; Send 1
    @done:
        jsr _scl_release
        jsr _scl_assert
        dex
        bne @write

        jsr _sda_release
        jsr _read_bit  ; Sets C if NACK

        plx
        pla

        rts

; Read byte with ACK
;
; Return:
;   A - data
read_ack:
        phx

        jsr _sda_release

        lda #0
        ldx #8
    @read:
        jsr _read_bit
        rol
        dex
        bne @read

        jsr _sda_assert
        jsr _scl_release
        jsr _scl_assert

        plx

        rts

; Read byte with NACK
;
; Return:
;   A - data
read_nack:
        phx

        jsr _sda_release

        lda #0
        ldx #8
    @read:
        jsr _read_bit
        rol
        dex
        bne @read

        jsr _scl_release
        jsr _scl_assert

        plx

        rts

_sda_assert:
        pha

        ; Ensure SDA is low (it might be messed up by others who use Port B)
        lda VIA1_RB
        and #(SDA ^ $FF)
        sta VIA1_RB
        ; Set SDA to output (pull to ground)
        lda VIA1_DDRB
        ora #SDA
        sta VIA1_DDRB
        jsr wait8us

        pla

        rts

_sda_release:
        pha

        ; Set SDA to input (pulled up)
        lda VIA1_DDRB
        and #(SDA ^ $FF)
        sta VIA1_DDRB
        jsr wait8us

        pla

        rts

_scl_assert:
        pha

        ; Ensure SDC is low (it might be messed up by others who use Port B)
        lda VIA1_RB
        and #(SCL ^ $FF)
        sta VIA1_RB

        lda VIA1_DDRB
        ora #SCL
        sta VIA1_DDRB
        jsr wait8us

        pla

        rts

_scl_release:
        pha

        lda VIA1_DDRB
        and #(SCL ^ $FF)
        sta VIA1_DDRB
        jsr wait8us

        pla

        rts

; Return:
;   C - set to bit that was read
_read_bit:
        pha

        jsr _scl_release
        lda VIA1_RB
        jsr _scl_assert

        and #SDA
        clc
        adc #$FF  ; Carry will be set if SDA=1

        pla

        rts

; __fastcall__ variants

; byte _i2c_write(byte data)
_i2c_write:
        jsr write
        lda #0
        adc #0
        rts

; byte _i2c_read(bool ack)
_i2c_read:
        cmp #1
        bcc @nack
        jsr read_ack
        jmp @end
    @nack:
        jsr read_nack
    @end:
        rts
