/*
 * PS/2 keyboard implementation for ATmega328P
 * Supports multi-layer keymaps inspired by QMK firmware (https://qmk.fm/)
 * Keyboard is organized in 6x8 grid to save pins (versus 12x4 arrangement).
 * Matrix scanning order (diode direction) is row-to-column (rows are outputs, columns are inputs).
 * See ../../kicad/keyboard.kicad_sch for schematic
 */

#include <Arduino.h>

#include "scancodes.h"

#define COL_COUNT 6
#define ROW_COUNT 8
#define LAYERS    3

#define REPEAT_RATE       25
#define REPEAT_DELAY      200
#define DEBOUNCE_INTERVAL 10

#define PS2CLK  PIN_PD6
#define PS2DATA PIN_PD7

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
        SC_LCTRL, SC_ESC,   _____,    _____,    _____,    SC_SPACE,

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
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,

        // Right half
        SC_MINUS, EC_PGUP,  EC_UP,    EC_PGDN,  _____,    EC_DEL,
        EC_HOME,  EC_LEFT,  EC_DOWN,  EC_RIGHT, SC_GRAVE, _____,
        EC_END,   SC_EQUAL, SC_LBRAC, SC_RBRAC, _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        /* clang-format on */
    },
    {
        // Layer 2
        //

        /* clang-format off */
        // Left half
        _____,    SC_1,     SC_2,     SC_3,     SC_4,     SC_5,
        _____,    SC_F1,    SC_F2,    SC_F3,    SC_F4,    SC_F5,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,

        // Right half
        SC_6,     SC_7,     SC_8,     SC_9,     SC_0,     SC_F12,
        SC_F6,    SC_F7,    SC_F8,    SC_F9,    SC_F10,   SC_F11,
        _____,    _____,    _____,    _____,    _____,    _____,
        _____,    _____,    _____,    _____,    _____,    _____,
        /* clang-format on */
    },
};

#define INACTIVE 0xFF

// Defines which layer the key was pressed on and when.
typedef struct {
    // Layer on which the key was pressed, INACTIVE (0xFF) if not pressed.
    // We track this to properly break the key when it's released in case the layer has changed.
    uint8_t layer;
    // Is the key physically pressed at any point in time.
    // This is a raw value which is not debounced.
    // It's used to generate clean value for `layer` after debouncing.
    uint8_t phys;
    // When was the key pressed (for debouncing)
    uint32_t changedAt;
} key_state_t;

key_state_t keyStates[COL_COUNT * ROW_COUNT];
uint8_t currentLayer = 0;

// Last pressed key to repeat
uint16_t lastPressedKey = 0;
uint32_t nextRepeatAt = 0;

uint16_t handle_key(uint16_t keycode, bool isPressed);
void emit(uint16_t code, bool make);
void write(uint8_t code);
void writeBit(uint8_t bit);

// typedef struct {
//     uint8_t index;
//     uint16_t code;
//     uint32_t pressedAt;
// } pressed_key_info_t;

void setup() {
    pinMode(PS2CLK, OUTPUT);
    pinMode(PS2DATA, OUTPUT);
    digitalWrite(PS2CLK, HIGH);
    digitalWrite(PS2DATA, HIGH);
    for (uint8_t y = 0; y < ROW_COUNT; y++) {
        pinMode(ROWS[y], OUTPUT);
        digitalWrite(ROWS[y], HIGH);
    }
    for (uint8_t x = 0; x < COL_COUNT; x++) {
        pinMode(COLS[x], INPUT_PULLUP);
    }
    for (int i = 0; i < COL_COUNT * ROW_COUNT; i++) {
        keyStates[i].layer = INACTIVE;
        keyStates[i].phys = HIGH;
        keyStates[i].changedAt = 0;
    }

    // Send BAT
    delay(500);
    write(0xAA);
    delay(250);
}

// Scan the matrix
void loop() {
    if (lastPressedKey && millis() > nextRepeatAt) {
        emit(lastPressedKey, true);
        nextRepeatAt = millis() + 1000 / REPEAT_RATE;
    }

    for (uint8_t y = 0; y < ROW_COUNT; y++) {
        digitalWrite(ROWS[y], LOW);
        for (uint8_t x = 0; x < COL_COUNT; x++) {
            bool isPressed = digitalRead(COLS[x]) == LOW; // Key at (x;y) is pressed
            uint8_t index = y * COL_COUNT + x;
            key_state_t *keyState = &keyStates[index];
            bool wasPressed = keyState->phys;
            if (isPressed != wasPressed) {
                // Key state changed, start debouncing timer
                keyState->phys = isPressed;
                keyState->changedAt = millis();
            }

            // Check if debounce interval passed
            if (millis() - keyState->changedAt > DEBOUNCE_INTERVAL) {
                // Debounce interval passed
                bool wasActive = keyState->layer != INACTIVE;
                bool isActive = keyState->phys;
                if (isActive != wasActive) {
                    if (isActive) {
                        // Key pressed and is stable
                        keyState->layer = currentLayer;
                        lastPressedKey = handle_key(KEYMAP[currentLayer][index], true);
                        nextRepeatAt = millis() + REPEAT_DELAY;
                    } else {
                        // Key released and is stable
                        handle_key(KEYMAP[keyState->layer][index], false);
                        lastPressedKey = 0;
                        keyState->layer = INACTIVE;
                    }
                }
            }
        }
        digitalWrite(ROWS[y], HIGH);
    }
}

// Decide what to do when the key is pressed/released
uint16_t handle_key(uint16_t keycode, bool isPressed) {
    if (keycode == CC_LYR1) {
        currentLayer = isPressed ? 1 : 0;
        return 0;
    } else if (keycode == CC_LYR2) {
        currentLayer = isPressed ? 2 : 0;
        return 0;
    } else if (keycode) {
        emit(keycode, isPressed);
        return keycode;
    }
    return 0;
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
