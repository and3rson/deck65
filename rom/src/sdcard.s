.zeropage

SDC_MISO  =  $1
; SDC_DO    =  SDC_MISO  ; Slave's DO
SDC_MOSI  =  $2
; SDC_DI    =  SDC_MOSI  ; Slave's DI
SDC_CS    =  $4
SDC_SCK   =  $8

SDC_HEADER = %01000000

.code

.scope sdc
enable:
        pha
        phx

        lda VIA1_RB
        ldx #16  ; Pulse clock, 8 cycles
    @pulse:
        eor #SDC_SCK  ; Toggle edge
        sta VIA1_RB
        nop
        nop
        dex
        bne @pulse

        and #(SDC_CS ^ $FF)  ; Assert CS
        sta VIA1_RB

        ; Wait for CS to settle
        jsr wait32us

        plx
        pla

        rts

disable:
        pha

        lda VIA1_RB
        ora #SDC_CS  ; Release CS
        sta VIA1_RB

        ; Wait for CS to settle
        lda #16
    @again:
        dec
        bne @again

        pla

        rts

init:
        phx

        ; stz VIA1_RB  ; Ensure outputs are low
        ; jsr wait32us
        ; lda #$FF
        ; sta VIA1_RB
        ; jmp init

        ; Wait at least 1 ms
        jsr wait2ms

        lda VIA1_RB
        ora #((SDC_MOSI | SDC_CS) & ~SDC_SCK)  ; DI=1, CS=1, SCK=0
        sta VIA1_RB

        ; Send 74 clock cycles
        ldx #80*2
    @warmup:
        eor #SDC_SCK
        sta VIA1_RB
        nop
        nop
        nop
        nop
        dex
        bne @warmup

        ; Send CMD0
        ; jsr enable
        ; lda #%01000000
        ; jsr write
        ; jsr commit  ; Checksum, stop bit, & pull MOSI high
        ; jsr disable

        jsr enable

        ; CMD0 - init
        jsr _send_cmd0
        jsr _wait_byte
        cmp #$01
        bne @readiness_timeout
        jsr _read_byte  ; read tail

        ; CMD8 - send voltage
        jsr _send_voltage_check
        jsr _wait_byte  ; read header
        jsr _skip_byte4  ; 32 bits
        jsr _skip_byte  ; read tail
        cmp #$01
        bne @voltage_failed
        ; Read 32-bit voltage response

        ; CMD58 (7A) - send OCR
        jsr _send_ocr
        jsr _wait_byte  ; read header
        jsr _skip_byte4  ; 32 bits
        jsr _skip_byte  ; read tail
        cmp #$01
        bne @ocr_failed

        ; CMD55 - send app cmd
        jsr _send_app
        jsr _wait_byte  ; read header
        jsr _skip_byte  ; read tail
        cmp #$01
        bne @app_failed

        ; CMD41 - send app op cond
        jsr _send_op_cond
        jsr _wait_byte  ; read header
        jsr _skip_byte  ; read tail
        cmp #$01  ; initialization in progress?
        bne @op_cond_failed

        ldx #$FF  ; 256 attempts
    @wait_init:
        ; CMD55 - send app cmd
        jsr _send_app
        jsr _wait_byte  ; read header
        jsr _skip_byte  ; read tail

        ; CMD41 - send app op cond
        jsr _send_op_cond
        jsr _wait_byte  ; read header
        jsr _skip_byte  ; read tail
        cmp #$00  ; initialization finished?
        beq @wait_ok

        jsr wait32us
        dex
        bne @wait_init  ; retry
        ; Max attempts reached, fail
        jmp @init_timeout

    @wait_ok:
        ; ; CMD16 - send set blocklen
        ; jsr send_set_blocklen
        ; jsr wait_byte  ; read header
        ; jsr skip_byte  ; read tail
        ; cmp #$01
        ; bne @set_blocklen_failed
        ; CMD58 (7A) - send OCR
        jsr _send_ocr
        jsr _wait_byte  ; read header
        jsr _skip_byte4  ; 32 bits
        jsr _skip_byte  ; read tail
        ; Bit 30 of OCR should now contain 1 (the card is a high-capacity card known as SDHC/SDXC)
        ; cmp #$01
        ; bne @ocr_failed

        lda #0
        jmp @end

    @readiness_timeout:
        lda #$E1
        jmp @end

    @voltage_failed:  ; SDHC unsupported, possibly card is SDSC
        lda #$E2
        jmp @end

    @ocr_failed:
        lda #$E3
        jmp @end

    @app_failed:
        lda #$E4
        jmp @end

    @op_cond_failed:
        lda #$E5
        jmp @end

    @init_timeout:
        lda #$E6
        jmp @end

    @set_blocklen_failed:
        lda #$E7

    @end:
        jsr disable

        plx

        rts

read_block_start:
        phx

        jsr enable

        jsr _send_read_single_block
        jsr _wait_byte
        cmp #0  ; ok?
        bne @end  ; error
        jsr _wait_byte  ; Wait for data token
        cmp #$FE
        bne @end  ; error

    @end:
        plx

        rts

read_block_next = _read_byte

read_block_end:
        ; Read checksum
        jsr _read_byte
        jsr _read_byte

        jsr disable


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Private routines follow below


; CMD17 (51)
_send_read_single_block:
        pha

        lda #(17 | SDC_HEADER)
        jsr _write_byte
        ; TODO
        lda #0  ; first block
        jsr _write_byte  ; high byte?
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte  ; low byte?
        ; lda #%10010101  ; CRC & stop bit - unnecessary?
        lda #$3B  ; CRC & stop bit - unnecessary?
        jsr _write_byte

        pla

        rts

; CMD0 - Init
_send_cmd0:
        pha

        lda #(0 | SDC_HEADER)
        jsr _write_byte
        lda #0  ; arguments
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        lda #$95  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

; CMD8
_send_voltage_check:
        pha

        lda #(8 | SDC_HEADER)
        jsr _write_byte
        lda #0  ; arguments
        jsr _write_byte
        jsr _write_byte
        lda #1
        jsr _write_byte
        lda #$AA
        jsr _write_byte
        lda #$87  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

; CMD58 (7A)
_send_ocr:
        pha

        lda #(58 | SDC_HEADER)
        jsr _write_byte
        lda #0  ; arguments
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        lda #%01110101  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

; CMD55
_send_app:
        pha

        lda #(55 | SDC_HEADER)
        jsr _write_byte
        lda #0  ; arguments
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        ; lda #%11111111  ; CRC & stop bit
        lda #$55  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

; CMD41
_send_op_cond:
        pha

        lda #(41 | SDC_HEADER)
        jsr _write_byte
        lda #%01000000  ; arguments
        jsr _write_byte
        lda #0
        jsr _write_byte
        jsr _write_byte
        jsr _write_byte
        ; lda #%11111111  ; CRC & stop bit
        lda #$77  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

; CMD16
_send_set_blocklen:
        pha

        lda #(16 | SDC_HEADER)
        jsr _write_byte
        lda #0  ; arguments
        jsr _write_byte
        jsr _write_byte
        lda #$02
        jsr _write_byte
        lda #0
        jsr _write_byte
        lda #$81  ; CRC & stop bit
        jsr _write_byte

        pla

        rts

_write_byte:
        pha
        phx
        phy

        ldx #8
    @send_bit:
        tay
        and #$80
        bne @set_1
    @set_0:
        lda VIA1_RB
        and #(SDC_MOSI ^ $FF)
        jmp @write
    @set_1:
        lda VIA1_RB
        ora #SDC_MOSI
    @write:
        sta VIA1_RB

        lda VIA1_RB
        ; Pulse clock
        eor #SDC_SCK
        sta VIA1_RB
        nop
        nop
        eor #SDC_SCK
        sta VIA1_RB
        nop
        nop

        tya
        rol

        dex
        bne @send_bit

        ply
        plx
        pla

        rts

_read_byte:
        phx
        phy

        lda #0
        ldx #8
    @read_bit:
        lda VIA1_RB
        ; Pulse clock
        eor #SDC_SCK
        sta VIA1_RB
        nop
        nop

        lda VIA1_RB
        ror
        tya
        rol
        tay

        lda VIA1_RB
        eor #SDC_SCK
        sta VIA1_RB
        nop
        nop

        dex
        bne @read_bit

        tya

        ply
        plx

        rts

_skip_byte:
        pha

        jsr _read_byte

        pla

        rts

_skip_byte4:
        pha

        jsr _read_byte
        jsr _read_byte
        jsr _read_byte
        jsr _read_byte

        pla

        rts

_wait_byte:
        phx

        ldx #$FF  ; 255 attempts
    @again:
        jsr _read_byte
        cmp #$FF  ; is busy?
        bne @end  ; no, return data
        jsr wait32us
        dex
        bne @again  ; try again
        ; Max attempts reached, return $FF

    @end:
        plx

        rts
.endscope
