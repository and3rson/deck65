;
; Main file
;

.feature string_escapes

.include "define.s"

; Zeropage & stack
; zp.s must ALWAYS be defined first
.include "zp.s"

; I/O
.include "io.s"

; Kernel
.include "lcd.s"
.include "ps2kbd.s"
.include "sdcard.s"
.include "fat16.s"
.include "vdelay.s"
.include "functions.s"
.include "urepl.s"
.include "init.s"

; System
.include "interrupts.s"
.include "vectors.s"
