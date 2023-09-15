# Keyboard

Firmware for ATmega328P-powered mechanical PS/2 keyboard.

Inspired by [QMK firmware](https://qmk.fm/).

Features:

- Key press delay & repeat
- Switch debouncing
- Basic & extended make/break scancodes
- Multi-layer support (extending total number of possible unique keys to thousands)

  I use two layer keys: "alpha" & "beta".
  - Main layer contains QWERTY layout and most used function keys (Ctrl/Alt/Shift/Meta, Return, Backspace, Escape, etc)
  - "Alpha" activates navigation layer (I/J/K/L = Up/Left/Down/Right, H/N = Home/End, U/O = PageUp/PageDown, etc)
  - "Beta" activates digits and F-keys.
  See (source code)[./src/main.c] for keyboard layout.
