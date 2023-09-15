# Keyboard

*- 48 keys is all you need.*

Firmware for ATmega328P-powered mechanical PS/2 keyboard.

Inspired by [QMK firmware](https://qmk.fm/).

## Features

- Key press delay & repeat
- Switch debouncing
- Basic & extended make/break scancodes
- Multi-layer support (extending total number of possible unique keys to thousands)

  I use two layer keys: "alpha" & "beta".
  - Main layer contains QWERTY layout and most used function keys (Ctrl/Alt/Shift/Meta, Return, Backspace, Escape, etc)
  - "Alpha" activates navigation layer (I/J/K/L = Up/Left/Down/Right, H/N = Home/End, U/O = PageUp/PageDown, etc)
  - "Beta" activates digits and F-keys.

## Keyboard layout

### Main layer
```
┏━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┓
┃ TAB ┃  Q  │  W  │  E  │  R  │  T  ┃  Y  │  U  │  I  │  O  │  P  ┃BKSPC┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃  𝛼  ┃  A  │  S  │  D  │  F  │  G  ┃  H  │  J  │  K  │  L  │  ;  ┃ RET ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃SHIFT┃  Z  │  X  │  C  │  V  │  B  ┃  N  │  M  │  ,  │  .  │  /  ┃ CTRL┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃ CTRL┃ ESC │     │     │     │SPACE┃SPACE│  𝛽  │     │     │     ┃     ┃
┗━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┛
```

### Alpha layer
```
┏━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┓
┃     ┃     │     │     │     │     ┃  -  │ PGUP│  UP │ PGDN│     ┃ DEL ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃     │     │     │     │     ┃ HOME│ LEFT│  K  │RIGHT│  `  ┃     ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃     │     │     │     │     ┃ END │  =  │  [  │  ]  │     ┃     ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃     │     │     │     │     ┃     │     │     │     │     ┃     ┃
┗━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┛
```

### Beta layer
```
┏━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┯━━━━━┯━━━━━┯━━━━━┯━━━━━┳━━━━━┓
┃     ┃  1  │  2  │  3  │  4  │  5  ┃  6  │  7  │  8  │  9  │  0  ┃ F12 ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃  F1 │  F2 │  F3 │  F4 │  F5 ┃  F6 │  F7 │  F8 │  F9 │ F10 ┃ F11 ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃     │     │     │     │     ┃     │     │     │     │     ┃     ┃
┣━━━━━╉─────┼─────┼─────┼─────┼─────╂─────┼─────┼─────┼─────┼─────╊━━━━━┫
┃     ┃     │     │     │     │     ┃     │     │     │     │     ┃     ┃
┗━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┻━━━━━┛
```

