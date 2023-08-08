/*
 * PS/2 keyboard implementation for ATmega328P
 * Supports multi-layer keymaps inspired by QMK firmware (https://qmk.fm/)
 * Keyboard is organized in 6x8 grid to save pins (versus 12x4 arrangement).
 * Matrix scanning order (diode direction) is column-to-row (columns are outputs, rows are inputs).
 * See ../../kicad/keyboard.kicad_sch for schematic
 */

#include <Arduino.h>

#include "scancodes.h"

#define ROW_COUNT 8
#define COL_COUNT 6
#define LAYERS    3

#define PS2CLK  PD6
#define PS2DATA PD7

const uint8_t COLS[COL_COUNT] = {PIN_PB0, PIN_PB1, PIN_PB2, PIN_PB3, PIN_PB4, PIN_PB5};
const uint8_t ROWS[ROW_COUNT] = {PIN_PD0, PIN_PD1, PIN_PD2, PIN_PD3, PIN_PC4, PIN_PC3, PIN_PC2, PIN_PC1};
const uint16_t KEYMAP[LAYERS][COL_COUNT * ROW_COUNT] = {
    {
        // Layer 0
        //

        /* clang-format off */
        // Left half
        SC_TAB,   SC_Q,     SC_W,     SC_E,     SC_R,     SC_T,
        CC_LYR1,  SC_A,     SC_S,     SC_D,     SC_F,     SC_G,
        SC_LSHFT, SC_Z,     SC_X,     SC_C,     SC_V,     SC_B,
        SC_LCTRL, _____,    _____,    _____,    _____,    SC_SPACE,

        // Right half
        SC_Y,     SC_U,     SC_I,     SC_O,     SC_P,     SC_BKSPC,
        SC_H,     SC_J,     SC_K,     SC_L,     SC_SMCLN, SC_ENTER,
        SC_N,     SC_M,     SC_COMMA, SC_PRIOD, SC_SLASH, SC_LCTRL,
        SC_SPACE, CC_LYR2,  _____,    _____,    _____,    _____,
        /* clang-format on */
    },
    {
        // Layer 1
        //

        /* clang-format off */
        // Left half
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    SC_ESC,   _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,

        // Right half
        _____,    EC_PGUP,  EC_UP,    EC_PGDN,  _____,    _____,
        EC_HOME,  EC_LEFT,  EC_DOWN,  EC_RIGHT, _____,    _____,
        EC_END,   _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        /* clang-format on */
    },
    {
        // Layer 2
        //

        /* clang-format off */
        // Left half
        _____,    SC_1,     SC_2,     SC_3,     SC_4,     SC_5,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,

        // Right half
        SC_6,     SC_7,     SC_8,     SC_9,     SC_0,     _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        /* clang-format on */
    },
};

#define INACTIVE 0xFF

// keyStates maps keys to layers they were pressed on.
// If key is not pressed, it's set to INACTIVE (0xFF).
// Otherwise, it contains the number of layer on which it was pressed.
// We track this to properly break the key when it's released in case the layer has changed.
uint16_t keyStates[48];
uint8_t currentLayer = 0;

void handle_key(uint16_t keycode, bool isPressed);
void emit(uint16_t code, bool make);
void write(uint8_t code);
void writeBit(uint8_t bit);

void setup() {
    pinMode(PS2CLK, OUTPUT);
    pinMode(PS2DATA, OUTPUT);
    digitalWrite(PS2CLK, HIGH);
    digitalWrite(PS2DATA, HIGH);
    for (uint8_t x = 0; x < COL_COUNT; x++) {
        pinMode(COLS[x], OUTPUT);
    }
    for (uint8_t y = 0; y < ROW_COUNT; y++) {
        pinMode(ROWS[y], OUTPUT);
        digitalWrite(ROWS[y], INPUT_PULLUP);
    }
    for (int i = 0; i < 48; i++) {
        keyStates[i] = INACTIVE;
    }

    // Send BAT
    delay(500);
    write(0xAA);
    delay(250);
}

// Scan the matrix
void loop() {
    for (uint8_t x = 0; x < COL_COUNT; x++) {
        digitalWrite(COLS[x], LOW);
        for (uint8_t y = 0; y < ROW_COUNT; y++) {
            bool isPressed = digitalRead(ROWS[y]) == LOW; // Key at (x;y) is pressed
            uint8_t index = y * COL_COUNT + x;
            bool wasPressed = keyStates[index] != INACTIVE;
            if (isPressed != wasPressed) {
                // Key state changed
                if (isPressed) {
                    // Pressed
                    keyStates[index] = currentLayer;
                    handle_key(KEYMAP[currentLayer][index], true);
                } else {
                    // Released
                    handle_key(KEYMAP[keyStates[index]][index], false);
                    keyStates[index] = INACTIVE;
                }
            }
        }
        digitalWrite(COLS[x], HIGH);
    }
}

// Decide what to do when the key is pressed/released
void handle_key(uint16_t keycode, bool isPressed) {
    if (keycode == CC_LYR1) {
        currentLayer = isPressed ? 1 : 0;
    } else if (keycode == CC_LYR2) {
        currentLayer = isPressed ? 2 : 0;
    } else {
        emit(keycode, isPressed);
    }
}

// Send PS/2 make/break sequence
void emit(uint16_t code, bool make) {
    if (!make) {
        write(0xF0);
    }
    if (code > 0xFF) {
        write((code >> 8) & 0xFF);
        code = code & 0xFF;
    }
    write(code);
}

// Write PS/2 packet
void write(uint8_t code) {
    writeBit(0); // Start bit
    uint8_t parity = 1;
    for (uint8_t i = 0; i < 8; i++) {
        // Data bits (LSB first)
        uint8_t bit = code & 0x01;
        writeBit(bit);
        parity += bit;
        code >>= 1;
    }
    writeBit(parity % 2);  // Parity bit
    writeBit(1);           // Stop bit
    delayMicroseconds(50); // Wait one entire clock cycle
}

// Write single bit with PS/2 clock cycle
void writeBit(uint8_t bit) {
    digitalWrite(PS2DATA, bit);
    delayMicroseconds(1);
    digitalWrite(PS2CLK, LOW);
    delayMicroseconds(25);
    digitalWrite(PS2CLK, HIGH);
    delayMicroseconds(25);
}
