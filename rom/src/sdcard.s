.zeropage

SDC_MISO  =  $1
; SDC_DO    =  SDC_MISO  ; Slave's DO
SDC_MOSI  =  $2
; SDC_DI    =  SDC_MOSI  ; Slave's DI
SDC_CS    =  $4
SDC_SCK   =  $8

SDC_HEADER = %01000000

SDC_DAT: .res 1

.bss

SDC_BUFFER = $1000

.code

sdc_enable:
        pha

        lda #8
    @pulse:
        jsr sdc_clock_high
        nop
        nop
        jsr sdc_clock_low
        nop
        nop
        dec
        bne @pulse

        lda VIA1_RB
        and #(SDC_CS ^ $FF)
        sta VIA1_RB
        lda #8

        pla

        rts

sdc_disable:
        pha
        lda VIA1_RB
        ora #SDC_CS
        sta VIA1_RB
        pla
        rts

sdc_clock_high:
        pha
        lda VIA1_RB
        ora #SDC_SCK
        sta VIA1_RB
        pla
        rts

sdc_clock_low:
        pha
        lda VIA1_RB
        and #(SDC_SCK ^ $FF)
        sta VIA1_RB
        pla
        rts

sdc_init:
        phx

        ; stz VIA1_RB  ; Ensure outputs are low
        ; jsr lcd_wait32us
        ; lda #$FF
        ; sta VIA1_RB
        ; jmp sdc_init

        ; Wait at least 1 ms
        jsr lcd_wait2ms

        lda #(SDC_MOSI | SDC_CS)  ; DI=1, CS=1
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
        ; jsr sdc_enable
        ; lda #%01000000
        ; jsr sdc_write
        ; jsr sdc_commit  ; Checksum, stop bit, & pull MOSI high
        ; jsr sdc_disable

        jsr sdc_enable

        ; CMD0 - init
        jsr sdc_send_cmd0
        jsr sdc_wait_byte
        cmp #$01
        bne @readiness_timeout
        jsr sdc_read_byte  ; read tail

        ; CMD8 - send voltage
        jsr sdc_send_voltage_check
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte4  ; 32 bits
        jsr sdc_skip_byte  ; read tail
        cmp #$01
        bne @voltage_failed
        ; Read 32-bit voltage response

        ; CMD58 (7A) - send OCR
        jsr sdc_send_ocr
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte4  ; 32 bits
        jsr sdc_skip_byte  ; read tail
        cmp #$01
        bne @ocr_failed

        ; CMD55 - send app cmd
        jsr sdc_send_app
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte  ; read tail
        cmp #$01
        bne @app_failed

        ; CMD41 - send app op cond
        jsr sdc_send_op_cond
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte  ; read tail
        cmp #$01  ; initialization in progress?
        bne @op_cond_failed

        ldx #$FF  ; 256 attempts
    @wait_init:
        ; CMD55 - send app cmd
        jsr sdc_send_app
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte  ; read tail

        ; CMD41 - send app op cond
        jsr sdc_send_op_cond
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte  ; read tail
        cmp #$00  ; initialization finished?
        beq @wait_ok

        dex
        bne @wait_init  ; retry
        ; Max attempts reached, fail
        jmp @init_timeout

    @wait_ok:
        ; ; CMD16 - send set blocklen
        ; jsr sdc_send_set_blocklen
        ; jsr sdc_wait_byte  ; read header
        ; jsr sdc_skip_byte  ; read tail
        ; cmp #$01
        ; bne @set_blocklen_failed
        ; CMD58 (7A) - send OCR
        jsr sdc_send_ocr
        jsr sdc_wait_byte  ; read header
        jsr sdc_skip_byte4  ; 32 bits
        jsr sdc_skip_byte  ; read tail
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
        jsr sdc_disable

        plx

        rts

sdc_read_block:
        phx

        jsr sdc_enable
        jsr sdc_send_read_single_block
        jsr sdc_wait_byte
        cmp #0  ; ok?
        bne @end  ; error
        jsr sdc_wait_byte  ; Wait for data token
        cmp #$FE
        bne @end  ; error

        ldx #0
    @read:
        jsr sdc_read_byte
        sta SDC_BUFFER, X
        inx
        cpx #16
        bne @read

        lda #0
        sta SDC_BUFFER, X
        jmp @end

    @end:
        jsr sdc_disable

        plx

        rts

; CMD17 (51)
sdc_send_read_single_block:
        pha

        lda #(17 | SDC_HEADER)
        jsr sdc_write_byte
        ; TODO
        lda #0  ; first block
        jsr sdc_write_byte  ; high byte?
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte  ; low byte?
        ; lda #%10010101  ; CRC & stop bit - unnecessary?
        lda #$3B  ; CRC & stop bit - unnecessary?
        jsr sdc_write_byte

        pla

        rts

; CMD0 - Init
sdc_send_cmd0:
        pha

        lda #(0 | SDC_HEADER)
        jsr sdc_write_byte
        lda #0  ; arguments
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        lda #$95  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

; CMD8
sdc_send_voltage_check:
        pha

        lda #(8 | SDC_HEADER)
        jsr sdc_write_byte
        lda #0  ; arguments
        jsr sdc_write_byte
        jsr sdc_write_byte
        lda #1
        jsr sdc_write_byte
        lda #$AA
        jsr sdc_write_byte
        lda #$87  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

; CMD58 (7A)
sdc_send_ocr:
        pha

        lda #(58 | SDC_HEADER)
        jsr sdc_write_byte
        lda #0  ; arguments
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        lda #%01110101  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

; CMD55
sdc_send_app:
        pha

        lda #(55 | SDC_HEADER)
        jsr sdc_write_byte
        lda #0  ; arguments
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        ; lda #%11111111  ; CRC & stop bit
        lda #$55  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

; CMD41
sdc_send_op_cond:
        pha

        lda #(41 | SDC_HEADER)
        jsr sdc_write_byte
        lda #%01000000  ; arguments
        jsr sdc_write_byte
        lda #0
        jsr sdc_write_byte
        jsr sdc_write_byte
        jsr sdc_write_byte
        ; lda #%11111111  ; CRC & stop bit
        lda #$77  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

; CMD16
sdc_send_set_blocklen:
        pha

        lda #(16 | SDC_HEADER)
        jsr sdc_write_byte
        lda #0  ; arguments
        jsr sdc_write_byte
        jsr sdc_write_byte
        lda #$02
        jsr sdc_write_byte
        lda #0
        jsr sdc_write_byte
        lda #$81  ; CRC & stop bit
        jsr sdc_write_byte

        pla

        rts

sdc_write_byte:
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
        and #%11111101
        jmp @write
    @set_1:
        lda VIA1_RB
        ora #%00000010
    @write:
        sta VIA1_RB
        tya
        rol

        ; Pulse clock
        jsr sdc_clock_high
        nop
        nop
        jsr sdc_clock_low
        nop
        nop

        dex
        bne @send_bit

        ply
        plx
        pla

        rts

sdc_read_byte:
        phx
        phy

        lda #0
        ldx #8
    @read_bit:
        tay
        lda VIA1_RB
        and #1
        ror
        tya
        rol

        ; Pulse clock
        jsr sdc_clock_high
        nop
        nop
        nop
        nop
        jsr sdc_clock_low
        nop
        nop
        nop
        nop

        dex
        bne @read_bit

        ply
        plx

        rts

sdc_skip_byte:
        pha

        jsr sdc_read_byte

        pla

        rts

sdc_skip_byte4:
        pha

        jsr sdc_read_byte
        jsr sdc_read_byte
        jsr sdc_read_byte
        jsr sdc_read_byte

        pla

        rts

sdc_wait_byte:
        phx

        ldx #$FF  ; 255 attempts
    @again:
        jsr sdc_read_byte
        cmp #$FF  ; is busy?
        bne @end  ; no, return data
        nop  ; TODO
        jsr lcd_wait32us
        ; nop
        ; nop
        ; nop
        ; nop
        ; nop
        ; nop
        ; nop
        dex
        bne @again  ; try again
        ; Max attempts reached, return $FF

    @end:
        plx

        rts
