;
; Main file
;

.feature string_escapes

.include "define.s"

; Zeropage & stack
; zp.s must ALWAYS be defined first
.include "zp.s"
.include "program.s"

; Kernel (high 8K ROM)
.include "kore/io.s"
.include "kore/drivers/lcd.s"
.include "kore/drivers/ps2kbd.s"
.include "kore/drivers/sdcard.s"
.include "kore/drivers/fat16.s"

.include "kore/vdelay.s"
.include "kore/functions.s"
.include "kore/interrupts.s"
.include "kore/init.s"

; System (low 16K ROM)
.include "system/urepl.s"

; Vectors
.include "vectors.s"
