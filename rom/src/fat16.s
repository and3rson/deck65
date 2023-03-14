;
; FAT16 filesystem interface
;
; http://39k.ca/reading-files-from-fat16/
;

.scope fat16

.zeropage

MARKER:            .res  2
BOOTSEC:           .res  2

SEC_PER_CLU:       .res  1
RES_SEC_COUNT:     .res  2
FAT_COUNT:         .res  1
ROOT_DIR_ENTRIES:  .res  2
SEC_PER_FAT:       .res  2

F_NAME:  .res  8
F_EXT:   .res  3
F_SIZE:  .res  2
F_SEC:   .res  2

.segment "RAM"

START: .res 4096

.code

; Initialize FAT16 interface
; Reads MBR & boot sector, stores info in zeropage.
;
; Return:
;   A - 0 if success, non-zero if failed
init:
        phx

        lda #$AB
        sta MARKER
        lda #$CD
        sta MARKER+1

        ;;;;;;;;;;;;;;;;
        ; Read MBR

        lda #0
        ldx #0
        jsr sdc::read_block_start
        cmp #0  ; ok?
        beq @start_mbr_ok
        lda #$E1
        jmp @end
    @start_mbr_ok:

        ; Skip to $100
        ldx #0
    @skip100h:
        jsr sdc::read_block_byte
        dex
        bne @skip100h

        ; Skip to $1C6
        ldx #$C6
    @skipC6h:
        jsr sdc::read_block_byte
        dex
        bne @skipC6h

        ; Read sector number of boot sector (little-endian)

        jsr sdc::read_block_byte
        sta BOOTSEC
        jsr sdc::read_block_byte
        sta BOOTSEC+1

        ; Skip remaining 54 bytes (512-256-200-2)
        ldx #56
    @skip54:
        jsr sdc::read_block_byte
        dex
        bne @skip54

        ; Finish reading
        jsr sdc::read_block_end

        ;;;;;;;;;;;;;;;;
        ; Read boot sector

        lda BOOTSEC
        ldx BOOTSEC+1
        jsr sdc::read_block_start
        cmp #0  ; ok?
        beq @start_bootsec_ok
        lda #$E2
        jmp @end
    @start_bootsec_ok:

        ; Skip to $0D
        ldx #$0D
    @skip0Dh:
        jsr sdc::read_block_byte
        dex
        bne @skip0Dh

        ; Read filesystem info
        jsr sdc::read_block_byte  ; $0D
        sta SEC_PER_CLU

        jsr sdc::read_block_byte  ; $0E
        sta RES_SEC_COUNT
        jsr sdc::read_block_byte  ; $0F
        sta RES_SEC_COUNT+1

        jsr sdc::read_block_byte  ; $10
        sta FAT_COUNT

        jsr sdc::read_block_byte  ; $11
        sta ROOT_DIR_ENTRIES
        jsr sdc::read_block_byte  ; $12
        sta ROOT_DIR_ENTRIES+1

        jsr sdc::read_block_byte  ; $13..$15
        jsr sdc::read_block_byte
        jsr sdc::read_block_byte

        jsr sdc::read_block_byte  ; $16
        sta SEC_PER_FAT
        jsr sdc::read_block_byte  ; $17
        sta SEC_PER_FAT+1

        ; Skip remaining 489 bytes (256+233)
        ldx #0
    @skip256:
        jsr sdc::read_block_byte
        dex
        bne @skip256
        ldx #233
    @skip233:
        jsr sdc::read_block_byte
        dex
        bne @skip233

        ; Finish reading
        jsr sdc::read_block_end

        lda #0
        jmp @end

    @end:
        plx

        rts

; Find file by filename
; Stores file info in zeropage.
;
; Arguments:
;   A, X - low/high byte of string address
; Return:
;   A - 0 if file was found, 1 otherwise
find:
        phx

        ;

        plx

        rts


.endscope
