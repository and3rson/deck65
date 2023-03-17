;
; FAT16 filesystem interface
;
; IMPORTANT: File names with whitespaces won't work properly because I'm too lazy to fix string comparison for them.
;
; References:
; http://39k.ca/reading-files-from-fat16/
; http://www.maverick-os.dk/FileSystemFormats/FAT16_FileSystem.html
;

.scope fat16

.zeropage

MARKER:              .res  2
BOOTSEC:             .res  2

SEC_PER_CLU:         .res  1
RES_SEC_COUNT:       .res  2
FAT_COUNT:           .res  1
ROOT_DIR_ENTRIES:    .res  2
SEC_PER_FAT:         .res  2

FAT_SEC:             .res  2  ; = BOOTSEC + RES_SEC_COUNT
FAT_SEC_COUNT:       .res  2  ; = SEC_PER_FAT * 2
ROOT_DIR_SEC:        .res  2  ; = FAT_SEC + FAT_SEC_COUNT
ROOT_DIR_SEC_COUNT:  .res  2  ; = ROOT_DIR_ENTRIES * 32 / 512 (>>4)
DATA_SEC:            .res  2  ; = ROOT_DIR_SEC + ROOT_DIR_SEC_COUNT

F_NAME_EXT: .res 11
F_NULL:     .res  1
F_CLU:      .res  2
F_SIZE:     .res  4

STR:      .res  2
PTR:      .res  2
COUNTER:  .res  1
SECT:     .res  2
ERR:      .res  1

.segment "RAM"

; BUFFER: .res 512  ; Reserved for reading sectors & parsing them in-memory
; START: .res 4096

.code

; Initialize FAT16 interface
; Reads MBR & boot sector, stores info in zeropage.
;
; Return:
;   C - set if error
init:
        pha
        phx

        lda #$AB
        sta MARKER
        lda #$CD
        sta MARKER+1
        stz F_NULL

        ;;;;;;;;;;;;;;;;
        ; Read MBR

        lda #0
        ldx #0
        jsr sdc::read_block_start
        bcc @start_mbr_ok
        lda #$E1
        sta ERR
        jmp @err
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
        bcc @start_bootsec_ok
        lda #$E2
        sta ERR
        jmp @err
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

        ; TODO: Check signature (0xAA55)

        ; Finish reading
        jsr sdc::read_block_end

        ;;;;;;;;;;;;;;;;
        ; Check if this geometry is supported
        lda SEC_PER_CLU
        cmp #1
        beq @sec_per_clu_ok
        lda #$E3
        sta ERR
        jmp @err
    @sec_per_clu_ok:

        ;;;;;;;;;;;;;;;;
        ; Calculate FAT sector & root dir sector

        ; FAT_SEC = BOOTSEC + RES_SEC_COUNT
        clc
        lda BOOTSEC
        adc RES_SEC_COUNT
        sta FAT_SEC
        lda BOOTSEC+1
        adc RES_SEC_COUNT+1
        sta FAT_SEC+1
        ; TODO: Check carry flag, if set - throw overflow error since we went past 16-bit LBA

        ; ROOT_DIR_SEC = FAT_SEC + SEC_PER_FAT * FAT_COUNT
        ; 1: FAT_SEC_COUNT = SEC_PER_FAT * FAT_COUNT
        lda SEC_PER_FAT
        rol  ; TODO: We assume FAT_COUNT is 2
        sta FAT_SEC_COUNT
        lda #0
        adc #0
        sta FAT_SEC_COUNT+1
        ; 2: ROOT_DIR_SEC = FAT_SEC + FAT_SEC_COUNT
        clc
        lda FAT_SEC
        adc FAT_SEC_COUNT
        sta ROOT_DIR_SEC
        lda FAT_SEC+1
        adc FAT_SEC_COUNT+1
        sta ROOT_DIR_SEC+1
        ; TODO: Check carry flag, throw error if set

        ; ROOT_DIR_SIZE = ROOT_DIR_ENTRIES * 32 / 512 (>>4)
        lda ROOT_DIR_ENTRIES
        sta ROOT_DIR_SEC_COUNT
        lda ROOT_DIR_ENTRIES+1
        sta ROOT_DIR_SEC_COUNT+1
        ldx #4
    @shift:
        clc
        lda ROOT_DIR_SEC_COUNT+1
        ror
        sta ROOT_DIR_SEC_COUNT+1
        lda ROOT_DIR_SEC_COUNT
        ror
        sta ROOT_DIR_SEC_COUNT
        dex
        bne @shift

        ; DATA_SEC = ROOT_DIR_SEC + ROOT_DIR_SEC_COUNT
        clc
        lda ROOT_DIR_SEC
        adc ROOT_DIR_SEC_COUNT
        sta DATA_SEC
        lda ROOT_DIR_SEC+1
        adc ROOT_DIR_SEC_COUNT+1
        sta DATA_SEC+1

        clc  ; success
        jmp @end

    @err:
        sec

    @end:
        plx
        pla

        rts

; Find file by filename
; Stores file info in zeropage.
;
; Arguments:
;   A, X - low/high byte of string address
; Return:
;   C - set if error
open:
        pha
        phx
        phy

        sta STR
        stx STR+1

        ; Read entire root directory sector-by-sector
        stz COUNTER  ; TODO: we assume root dir sector count is <256
    @next_sector:
        clc
        lda ROOT_DIR_SEC
        adc COUNTER
        pha
        lda ROOT_DIR_SEC+1
        adc #0
        pha
        ; Select sector ROOT_DIR_SEC+COUNTER
        plx
        pla
        jsr sdc::select_sector

        ; plx
        ; pla
        ; ldy #<sdc::SECTOR_DATA
        ; phy
        ; ldy #>sdc::SECTOR_DATA
        ; phy
        lda #<sdc::SECTOR_DATA
        ldx #>sdc::SECTOR_DATA
        jsr sdc::read_sector
        bcc @read_ok
        lda #$E1
        jmp @err
    @read_ok:
        ; Iterate on possible 16 files in this sector
        lda #<sdc::SECTOR_DATA
        sta PTR
        lda #>sdc::SECTOR_DATA
        sta PTR+1
        ldx #16
    @next_file:
        ; PTR is pointing at file entry start
        lda (PTR)  ; Is empty entry?
        beq @not_found ; No more files to read
        ldy #7
    @compare:
        lda (PTR), Y
        cmp (STR), Y
        bne @done
        dey
        bpl @compare
    @done:
        cpy #$FF
        beq @file_found
        ; Point to next file
        clc
        lda PTR
        adc #32
        sta PTR
        lda PTR+1
        adc #0
        sta PTR+1
        dex  ; Go to next file?
        bne @next_file

        ; No more files
        inc COUNTER
        lda COUNTER
        cmp ROOT_DIR_SEC_COUNT  ; Go to next sector?
        bne @next_sector

    @not_found:
        ; File not found
        lda #$E2
        jmp @err

    @file_found:
        ; Populate F_NAME_EXT (11 bytes)
        ldy #0
    @copy_f_name_ext:
        lda (PTR), Y
        sta F_NAME_EXT, Y
        iny
        cpy #11
        bne @copy_f_name_ext
        ; Populate F_CLU & F_SIZE (6 bytes)
        clc
        lda PTR
        adc #26
        sta PTR
        lda PTR+1
        adc #0
        sta PTR+1
        ldy #0
    @copy_f_clu_and_size:
        lda (PTR), Y
        sta F_CLU, Y
        iny
        cpy #6
        bne @copy_f_clu_and_size

        clc  ; success
        jmp @end

    @err:
        sta ERR
        sec

    @end:
        ply
        plx
        pla

        rts

; Read currently open file into memory
;
; Arguments:
;   A - memory low byte
;   X - memory high byte
; Return:
;   C - set if error
read:
        pha
        phx

        ; TODO: We are only reading 1 cluster for now.

        sta PTR
        stx PTR+1
        ; ldx SEC_PER_CLU  ; Read SEC_PER_CLU clusters
    ; @next:
        ; dex
        ; bne @next

        ; Calculate effective sector:
        ; SECT = DATA_SEC + F_CLU - 2
        ; SECT = F_CLU
        lda fat16::F_CLU
        sta SECT
        lda fat16::F_CLU+1
        sta SECT+1
        ; SECT -= 2
        sec
        lda SECT
        sbc #2
        sta SECT
        lda SECT+1
        sbc #0
        sta SECT+1
        ; SECT += DATA_SEC
        clc
        lda SECT
        adc DATA_SEC
        sta SECT
        lda SECT+1
        adc DATA_SEC+1
        sta SECT+1

        lda SECT
        ldx SECT+1
        jsr sdc::select_sector
        lda PTR
        ldx PTR+1
        jsr sdc::read_sector  ; sets carry flag on error
        bcs @err

        clc
        jmp @end

    @err:
        lda sdc::ERR
        sta ERR
        sec

    @end:
        plx
        pla

        rts

.endscope
