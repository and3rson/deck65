#include <Arduino.h>

#include "scancodes.h"

#define ROW_COUNT 8
#define COL_COUNT 6
#define LAYERS    1

const uint8_t COLS[COL_COUNT] = {PIN_PB0, PIN_PB1, PIN_PB2, PIN_PB3, PIN_PB4, PIN_PB5};
const uint8_t ROWS[ROW_COUNT] = {PIN_PD0, PIN_PD1, PIN_PD2, PIN_PD3, PIN_PC4, PIN_PC3, PIN_PC2, PIN_PC1};
const uint8_t KEYMAP[LAYERS][COL_COUNT * ROW_COUNT] = {
    {
        /* clang-format off */
        // Left half
        SC_TAB,   SC_Q,     SC_W,     SC_E,     SC_R,     SC_T,
        SC_ESC ,  SC_A,     SC_S,     SC_D,     SC_F,     SC_G,
        SC_LSHFT, SC_Z,     SC_X,     SC_C,     SC_V,     SC_B,
        SC_LCTRL, _____,    _____,    _____,    _____,    SC_SPACE,

        // Right half
        SC_Y,     SC_U,     SC_I,     SC_O,     SC_P,     SC_BKSPC,
        SC_H,     SC_J,     SC_K,     SC_L,     SC_SMCLN, SC_ENTER,
        SC_N,     SC_M,     SC_COMMA, SC_PRIOD, SC_SLASH, SC_LCTRL,
        SC_SPACE, _____,    _____,    _____,    _____,    _____,
        /* clang-format on */
    },
    // {
    //     /* clang-format off */
    //     // Left half
    //     _____,    _____,    _____,    _____,    _____,    _____,
    //     _____,    _____,    _____,    _____,    _____,    _____,
    //     _____,    _____,    _____,    _____,    _____,    _____,
    //     _____,    _____,    _____,    _____,    _____,    _____,
    //
    //     // Right half
    //     _____,    EC_PGUP,  EC_UP,    EC_PGDN,  _____,    _____,
    //     EC_HOME,  EC_LEFT,  EC_DOWN,  EC_RIGHT, _____,    _____,
    //     EC_END,   _____,    _____,    _____,    _____,    _____,
    //     _____,    _____,    _____,    _____,    _____,    _____,
    //     /* clang-format on */
    // },
};
#define PS2CLK  PD6
#define PS2DATA PD7

bool keyStates[48];
byte currentLayer = 0;

void emit(byte index, byte layer, bool make);
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

    // Send BAT
    delay(500);
    write(0xAA);
    delay(250);
}

void loop() {
    for (byte y = 0; y < ROW_COUNT; y++) {
        digitalWrite(ROWS[y], LOW);
        for (byte x = 0; x < COL_COUNT; x++) {
            bool isPressed = digitalRead(COLS[x]) == LOW; // Key at (x;y) is pressed
            byte index = y * COL_COUNT + x;
            if (keyStates[index] != isPressed) {
                // Key state changed
                emit(index, currentLayer, isPressed);
                keyStates[index] = isPressed;
            }
        }
        digitalWrite(ROWS[y], HIGH);
    }
}

void emit(byte index, byte layer, bool make) {
    byte scancode = KEYMAP[layer][index];
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
