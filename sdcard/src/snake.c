#include <stdio.h>
#include <conio.h>

#include <api/keyboard.h>
#include <api/wait.h>

// Main function should come first
int main();

typedef struct {
    byte x;
    byte y;
    byte prev;
    byte next;
} Part;
byte foodX, foodY;
byte dirX, dirY;
Part body[160];
byte bodyLength;
byte head, tail;
byte tick;

char s[2];

byte seed[] = {
    0x59, 0xC9, 0xAD, 0x4C, 0x2A, 0x61, 0x88, 0x0B, 0x6D, 0xB8, 0xC3, 0x28, 0xFB, 0xE5, 0xF6, 0xE3,
};
byte seedIndex = 0;

byte rand() {
    byte result;
    byte nextIndex = (seedIndex + 1) % 8;
    result = seed[seedIndex];
    seed[seedIndex] = seed[seedIndex] ^ seed[nextIndex];
    seedIndex = nextIndex;
    return result;
}

byte hello() {
    clrscr();
    gotoxy(8, 0);
    puts("         SNAKE          ");
    gotoxy(8, 1);
    puts("W/A/S/D - move, Q - quit");
    gotoxy(8, 2);
    puts("     Press any key");
    if (cgetc() == 'q') {
        puts("\n");
        return 0;
    }
    return 1;
}

byte game() {
    byte x = 0, y = 0;
    byte i;
    byte c;
    byte moved;
    byte newHead;
    byte newTail;
    byte newX, newY;
    foodX = 20;
    foodY = 2;
    dirX = 1;
    dirY = 0;
    tick = 0;

    body[0].x = 7;
    body[0].y = 1;
    body[0].prev = 0xFF;
    body[0].next = 1;
    body[1].x = 6;
    body[1].y = 1;
    body[1].prev = 0;
    body[1].next = 2;
    body[2].x = 5;
    body[2].y = 1;
    body[2].prev = 1;
    body[2].next = 0xFF;
    head = 0;
    tail = 2;
    bodyLength = 3;
    clrscr();
    for (i = 0; i < bodyLength; i++) {
        gotoxy(body[i].x, body[i].y);
        puts("\x01");
    }
    gotoxy(foodX, foodY);
    puts("*");
    while (1) {
        c = igetch();
        moved = 0;
        if (c == 'a') {
            if (body[head].y != body[body[head].next].y) {
                dirX = -1;
                dirY = 0;
            }
        }
        if (c == 'd') {
            if (body[head].y != body[body[head].next].y) {
                dirX = 1;
                dirY = 0;
            }
        }
        if (c == 'w') {
            if (body[head].x != body[body[head].next].x) {
                dirY = -1;
                dirX = 0;
            }
        }
        if (c == 's') {
            if (body[head].x != body[body[head].next].x) {
                dirY = 1;
                dirX = 0;
            }
        } else if (c == 'q') {
            puts("\n");
            return 0;
        }
        tick++;
        if (tick == 10) {
            tick = 0;
            // Move
            newX = body[head].x + dirX;
            newY = body[head].y + dirY;
            if (newX == 40) {
                newX = 0;
            } else if (newX == 0xFF) {
                newX = 39;
            }
            if (newY == 4) {
                newY = 0;
            } else if (newY == 0xFF) {
                newY = 3;
            }
            if (newX == foodX && newY == foodY) {
                // Found food
                newHead = bodyLength++;
                body[newHead].prev = 0xFF;
                body[newHead].next = head;
                body[newHead].x = newX;
                body[newHead].y = newY;
                body[head].prev = newHead;
                head = newHead;
                gotoxy(body[head].x, body[head].y);
                puts("\x01");
                gotoxy(body[head].x, body[head].y);
                foodX = rand() % 40;
                foodY = rand() % 4;
                // Draw new food
                gotoxy(foodX, foodY);
                puts("*");
            } else {
                // Check if about to eat self
                for (i = 0; i < bodyLength; i++) {
                    if (body[i].x == newX && body[i].y == newY) {
                        // Game over!
                        return 1;
                    }
                }
                // No food, simply move
                newHead = tail;
                newTail = body[tail].prev;
                body[newTail].next = 0xFF;
                body[newHead].prev = 0xFF;
                body[newHead].next = head;
                body[head].prev = tail;
                gotoxy(body[tail].x, body[tail].y);
                puts(".");

                body[newHead].x = newX;
                body[newHead].y = newY;
                gotoxy(body[newHead].x, body[newHead].y);
                /* s[0] = '0' + newHead; */
                /* puts(s); */
                puts("\x01");
                gotoxy(body[newHead].x, body[newHead].y);
                head = newHead;
                tail = newTail;
            }
        }
        wait16ms();
    }
}

byte game_over() {
    byte c;
    clrscr();
    gotoxy(15, 1);
    puts(" GAME OVER ");
    gotoxy(10, 2);
    puts(" R - retry, Q - quit ");
    while(1) {
        c = cgetc();
        if (c == 'q') {
            puts("\n");
            return 0;
        }
        if (c == 'r') {
            return 1;
        }
    }
}

int main() {
    if (!hello()) {
        return 0;
    }

    while (1) {
        if (!game()) {
            return 0;
        }
        if (!game_over()) {
            return 0;
        }
    }
}