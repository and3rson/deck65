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
.include "drivers/lcd.s"
.include "drivers/ps2kbd.s"
.include "drivers/sdcard.s"
.include "drivers/fat16.s"

.include "vdelay.s"
.include "functions.s"
.include "urepl.s"
.include "init.s"

; System
.include "interrupts.s"
.include "vectors.s"
