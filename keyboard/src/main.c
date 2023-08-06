#include <Arduino.h>

#include "scancodes.h"

#define ROW_COUNT 8
#define COL_COUNT 6

const uint8_t COLS[COL_COUNT] = {PB0, PB1, PB2, PB3, PB4, PB5};
const uint8_t ROWS[ROW_COUNT] = {PD0, PD1, PD2, PD3, PC4, PC3, PC2, PC1};
const uint8_t KEYMAP[COL_COUNT * ROW_COUNT] = {
    /* clang-format off */
    // Left half
    SC_TAB,   SC_Q,     SC_W,     SC_E,     SC_R,     SC_T,
    SC_ESC,   SC_A,     SC_S,     SC_D,     SC_F,     SC_G,
    SC_LSHFT, SC_Z,     SC_X,     SC_C,     SC_V,     SC_B,
    SC_LCTRL, 0,        0,        0,        0,        SC_SPACE,

    // Right half
    SC_Y,     SC_U,     SC_I,     SC_O,     SC_P,     SC_BKSPC,
    SC_H,     SC_J,     SC_K,     SC_L,     SC_SMCLN, SC_ENTER,
    SC_N,     SC_M,     SC_COMMA, SC_PRIOD, SC_SLASH, SC_LCTRL,
    SC_SPACE, 0,        0,        0,        0,        0,
    /* clang-format on */
};
#define PS2CLK  PD6
#define PS2DATA PD7

bool keyStates[48];

void emit(byte index, bool make);
void write(byte code);
void writeBit(byte bit);

void setup() {
    pinMode(PS2CLK, OUTPUT);
    pinMode(PS2DATA, OUTPUT);
    digitalWrite(PS2CLK, HIGH);
    digitalWrite(PS2DATA, HIGH);
    for (byte y = 0; y < ROW_COUNT; y++) {
        pinMode(ROWS[y], OUTPUT);
        digitalWrite(ROWS[y], HIGH);
    }
    for (byte x = 0; x < COL_COUNT; x++) {
        pinMode(COLS[x], INPUT_PULLUP);
    }
    for (int i = 0; i < 48; i++) {
        keyStates[i] = false;
    }
}

void loop() {
    for (byte y = 0; y < ROW_COUNT; y++) {
        digitalWrite(ROWS[y], LOW);
        for (byte x = 0; x < COL_COUNT; x++) {
            bool isPressed = digitalRead(COLS[x]) == LOW; // Key at (x;y) is pressed
            byte index = y * COL_COUNT + x;
            if (keyStates[index] != isPressed) {
                // Key state changed
                emit(index, isPressed);
                keyStates[index] = isPressed;
            }
        }
        digitalWrite(ROWS[y], HIGH);
    }
}

void emit(byte index, bool make) {
    byte scancode = KEYMAP[index];
    if (!make) {
        write(0xF0);
    }
    write(scancode);
}

void write(byte code) {
    writeBit(0); // Start bit
    byte parity = 1;
    for (byte i = 0; i < 8; i++) {
        // Data bits (LSB first)
        byte bit = code & 0x01;
        writeBit(bit);
        parity += bit;
        code >>= 1;
    }
    writeBit(parity % 2); // Parity bit
    writeBit(1);          // Stop bit
}

void writeBit(byte bit) {
    digitalWrite(PS2DATA, bit);
    delayMicroseconds(1);
    digitalWrite(PS2CLK, LOW);
    delayMicroseconds(25);
    digitalWrite(PS2CLK, HIGH);
    delayMicroseconds(25);
}
