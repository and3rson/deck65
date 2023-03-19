; Monochrome composite video signal generation test for ATtiny45.
;
; Made by Andrew Dunai.
;
; Timings are hard!
;
; Draws 4 vertical black/white bars in a non-interlaced mode (PAL, cycle-exact).
; (Well, timings used here don't match the spec, but hey - they are still *relatively* cycle-exact).
; Most AVR instructions take 1 cycle, and branching instructions take 2 (or 1 if branch was not taken).
;
; Wiring:
;
;   PIN 3 (COLOR) --> 470R -\
;                            +--> VIDEO OUT
;   PIN 4 (SYNC)  --> 1K  --/
;
; CPU must run at 8 MHz, 1 cycle = 1/8 us, so we've got 512 cycles per scanline.
; Why ATtiny45? Because I have a whole bunch of them!
;
; L/H/E fuses: 0x62, 0xDB, 0xFF
; http://eleccelerator.com/fusecalc/fusecalc.php?chip=attiny45&LOW=62&HIGH=DF&EXTENDED=FF&LOCKBIT=FF
;
; Resources:
;   - https://bradsprojects.com/generating-video-signals-with-a-microcontroller/
;   - http://martin.hinner.info/vga/pal.html
;   - http://www.batsocks.co.uk/readme/video_timing.htm
;   - https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-2586-AVR-8-bit-Microcontroller-ATtiny25-ATtiny45-ATtiny85_Datasheet.pdf

.include "tn45def.inc"

.equ color_bit = 1<<PINB3
.equ sync_bit = 1<<PINB4

; Counters
.def cl = r16
.def ch = r17
.def cb = r18
.def co = r19

; Levels
; COLOR = 0, SYNC = 0, OUT = 0 V
.def zero = r20
; COLOR = 0, SYNC = 1, OUT = 1.5 V
.def sync = r21
; COLOR = 1, SYNC = 1, OUT = 5 V
.def white = r22

; Color bit for EOR-ing black/white bars
.def buffer = r23

; AVR doesn't have immediate variant of EOR, so let's use register as operand
.def colorreg = r24

.cseg
.org 0x00

;;;;;;;;;;;;;;;;
; Initialize registers
;;;;;;;;;;;;;;;;
        ldi cl, sync_bit | color_bit
        out DDRB, cl

        ldi zero, 0
        ldi sync, sync_bit
        ldi white, sync_bit | color_bit

        ldi buffer, sync_bit

        ldi colorreg, color_bit

frame:

;;;;;;;;;;;;;;;;
; 5 long syncs
; Each sync is 32 us (256 cycles)
;;;;;;;;;;;;;;;;
        ldi ch, 5  ; uses last remaining cycle time from previous step
long_sync:
        ; - low 30 us (240 cycles)
        out PORTB, zero
        ldi cl, 237/3
        ; 238 more cycles
wait:
        dec cl
        brne wait  ; -1 cycle on last iteration
        ; 2 more cycles
        nop
        nop

        ; - high 2 us (16 cycles)
        out PORTB, sync
        ldi cl, 12/3
        ; 14 more cycles
wait2:
        dec cl
        brne wait2  ; -1 cycle on last iteration
        ; 3 more cycles

        dec ch
        brne long_sync  ; -1 cycle on last iteration
        ; 1 more cycle

;;;;;;;;;;;;;;;;
; 5 short syncs
; Each sync is 32 us (256 cycles)
;;;;;;;;;;;;;;;;
        ldi ch, 5  ; uses last remaining cycle time from previous step
short_sync:
        ; - low 2 us (16 cycles)
        out PORTB, zero
        ldi cl, 15/3
        ; 14 more cycles
wait3:
        dec cl
        brne wait3  ; -1 cycle on last iteration
        ; no more cycles

        ; - high 30 us (240 cycles)
        out PORTB, sync
        ldi cl, 234/3
        ; 238 more cycles
wait4:
        dec cl
        brne wait4  ; -1 cycle on last iteration
        ; 5 more cycles

        dec ch
        breq short_sync_done
        ; 3 more cycles
        nop
        rjmp short_sync

short_sync_done:
        ; 2 more cycles

;;;;;;;;;;;;;;;;
; Data (304 lines)
; Each line:
;  - sync 4 us (32 cycles)
;  - back porch 8 us (64 cycles)
;  - raster 52 us (416 cycles)
;;;;;;;;;;;;;;;;
        ldi co, 2  ; uses 1st of 2 remaining cycles from previous step
field_half:

        ldi ch, 312/2  ; uses 2nd of 2 remaining cycles from previous step
line:
        ; - normal sync 4 us (32 cycles)
        out PORTB, zero
        ldi cl, 30/3
        ; 30 more cycles
lwait1:
        dec cl
        brne lwait1  ; -1 cycle on last iteration
        ; 1 more cycle
        nop

        ; - back porch 8 us (64 cycles)
        out PORTB, sync
        ldi cl, 60/2
        ; 62 cycles
lwait2:
        dec cl
        brne lwait2
        ; 3 more cycles
        nop

        ; Raster 52 us (416 cycles)
        ; 4 bars, 104 cycles each
        ldi cb, 4
bar:
        eor buffer, colorreg
        out PORTB, buffer
        ldi cl, 93/3
        ; 102 more cycles
barwait:
        dec cl
        brne barwait
        ; 10 cycles remaining

        dec cb
        breq bars_done
        ; 8 cycles remaining
        nop
        nop
        nop
        nop
        nop
        rjmp bar  ; MUST have 1 cycle remaining after jump

bars_done:
        ; 7 cycles remaining

        dec ch
        breq lines_done
        ; 5 cycles remaining
        nop
        nop
        rjmp line  ; MUST have no cycles remaining after jump

lines_done:
        ; 4 cycles remaining
        dec co
        brne field_half  ; MUST have 1 cycle remaining after jump

;;;;;;;;;;;;;;;;
; 6 short syncs
; Each sync is 32 us (256 cycles)
;;;;;;;;;;;;;;;;
        ldi ch, 6  ; uses last remaining cycle time from previous step
short_sync_2:
        ; - low 2 us (16 cycles)
        out PORTB, zero
        ldi cl, 15/3
        ; 14 more cycles
wait5:
        dec cl
        brne wait5  ; -1 cycle on last iteration
        ; no more cycles

        ; - high 30 us (240 cycles)
        out PORTB, sync
        ldi cl, 231/3
        ; 238 more cycles
wait6:
        dec cl
        brne wait6  ; -1 cycle on last iteration
        ; 8 more cycles

        dec ch
        breq short_sync_2_done
        ; 6 more cycles
        nop
        nop
        nop
        nop
        rjmp short_sync_2  ; Must have no cycles remaining after jump

short_sync_2_done:
        ; 5 more cycles
        nop
        nop
        rjmp frame  ; MUST have 1 cycle remaining after jump
