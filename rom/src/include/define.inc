;
; Constants & macros
;

.feature string_escapes

; CLOCK = 4096000
CLOCK = 8192000
CYCLES_PER_US = CLOCK / 1000000

.macro acall addr, _a
    lda _a
    jsr addr
.endmacro
