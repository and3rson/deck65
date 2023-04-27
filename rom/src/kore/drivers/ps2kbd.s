;
; PS/2 protocol implementation
;
; Reference:
; http://www.burtonsys.com/ps2_chapweske.htm
;

.scope kbd

.export _cgetc = getch, _igetch = igetch
.export kbd_init = init
.export kbd_process = process
.export kbd_getch = getch

.zeropage

CNT:        .res  1
SCA:        .res  1
RDY:        .res  1
FLAGS:      .res  1  ; 7..3=n/c, 2=SHIFT, 1=EXT, 0=BREAK

FLAG_BREAK  =  $1
FLAG_EXT    =  $2
FLAG_SHIFT  =  $4

CHR: .res 1

SCA_EXT     =  $E0
SCA_BREAK   =  $F0
SCA_LSHIFT  =  $12
SCA_RSHIFT  =  $59

.segment "KORE"

; Map stolen from Ben Eater :)
KEYMAP:
    .byte "????????????? `?" ; 00-0F
    .byte "?????q1???zsaw2?" ; 10-1F
    .byte "?cxde43?? vftr5?" ; 20-2F
    .byte "?nbhgy6???mju78?" ; 30-3F
    .byte "?,kio09??./l;p-?" ; 40-4F
    .byte "??'?[=????",$0a,"]?\\??" ; 50-5F
    .byte "??????",$08,"??1?47???" ; 60-6F
    .byte "0.2568",$1b,"??+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF
KEYMAP_SHIFTED:
    .byte "????????????? ~?" ; 00-0F
    .byte "?????Q!???ZSAW@?" ; 10-1F
    .byte "?CXDE#$?? VFTR%?" ; 20-2F
    .byte "?NBHGY^???MJU&*?" ; 30-3F
    .byte "?<KIO)(??>?L:P_?" ; 40-4F
    .byte "??",'"',"?{+?????}?|??" ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568???+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF

init:
        stz CNT
        stz SCA
        stz RDY
        stz FLAGS
        stz CHR

        rts

; Process PS/2 bit, update keyboard state
;
; Arguments:
;   A - 0 or 1
process:
        pha
        phx
        phy

        ldx CNT
        inx
        stx CNT

        ; Decide what to do with bit
        cpx #1
        beq @end  ; Start bit, ignore
        cpx #10
        beq @end  ; Parity bit, ignore
        cpx #11
        beq @complete  ; Frame complete

        ; Handle PS/2 bit as data
        ror A
        ror SCA
        jmp @end

    @complete:
        ; Frame finished
        stz CNT
        ldx SCA
        ; Check is scancode is BREAK
        cpx #SCA_BREAK
        bne @check_ext
        smb0 FLAGS
        jmp @end
    @check_ext:
        ; Check is scancode is EXT
        cpx #SCA_EXT
        bne @check_bat
        smb1 FLAGS
        jmp @end
    @check_bat:
        ; Ignore BAT
        cpx #$AA
        beq @end

        ; Load all flags, clear BREAK & EXT
        lda FLAGS
        rmb0 FLAGS
        rmb1 FLAGS
        ; If make/break shift - update shift flag
        cpx #SCA_LSHIFT
        beq @update_shift
        cpx #SCA_RSHIFT
        beq @update_shift
        tay
        and #FLAG_BREAK  ; Is break flag set?
        bne @end
        tya
        and #FLAG_SHIFT  ; Is shift flag set?
        bne @shifted

        ; Convert scancode into character
        lda KEYMAP, X
        jmp @print
    @shifted:
        ; Convert scancode into shifted character
        lda KEYMAP_SHIFTED, X
    @print:
        sta CHR
        lda #1
        sta RDY
        jmp @end

    @update_shift:
        and #FLAG_BREAK
        bne @clear_shift
        smb2 FLAGS  ; Set shift flat
        jmp @end
    @clear_shift:
        rmb2 FLAGS  ; Clear shift flag
        jmp @end

    @end:
        ply
        plx
        pla

        rts


; Get character, block if keyboard buffer is empty
;
; Return:
;   A - character ASCII code
getch:
    @again:
        lda RDY
        beq @again  ; Keyboard register not ready yet

        ; Keyboard register is ready
        sei
        stz RDY  ; Clear readiness flag
        lda CHR  ; Read register
        cli

        rts


; Get character immediately, return 0 if keyboard buffer is empty
;
; Return:
;   A - character ASCII code
igetch:
        sei

        lda RDY
        bne @read  ; Keyboard register ready
        lda #0
        jmp @end

    @read:
        ; Keyboard register is ready
        stz RDY  ; Clear readiness flag
        lda CHR  ; Read register

    @end:
        cli

        rts


.endscope
