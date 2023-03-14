;
; Constants & macros
;

CLOCK = 4096000
CYCLES_PER_US = CLOCK / 1000000

.macro a8call addr, _a
    lda _a
    jsr addr
.endmacro

.macro ax16call addr, ax
    lda #<ax
    ldx #>ax
    jsr addr
.endmacro

.macro print ax
    ax16call lcd::printz, ax
.endmacro
