;
; ACIA UART helpers
;

.import acia_write
.import lcd_printchar
.import lcd_printfz
.export uart_init
.export uart_process
.export _uart_has_data = uart_has_data
.export _uart_get = uart_get
.export _uart_write = uart_write

.zeropage

UART_RD_PTR: .res 1
UART_WR_PTR: .res 1

.segment "SYSRAM"

UART_BUFFER: .res 256

.segment "KORE"

uart_init:
        stz UART_RD_PTR
        stz UART_WR_PTR

        rts

uart_process:
        phy

        ldy UART_WR_PTR
        iny
        sty UART_WR_PTR
        sta UART_BUFFER, Y

        ply

        rts

uart_has_data:
        sec
        sei
        lda UART_RD_PTR
        sbc UART_WR_PTR
        cli

        rts

uart_get:
        phy

        sei

        ldy UART_RD_PTR
        cpy UART_WR_PTR
        beq @empty

        iny
        sty UART_RD_PTR
        lda UART_BUFFER, Y
        jmp @end

    @empty:
        lda #0

    @end:
        cli

        ply

        rts

uart_write:
        jmp acia_write  ; (jsr, rts)

; .export _uart_reset
; _uart_reset:
;         stz UART_RD_PTR
;         rts

