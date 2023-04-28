#include <stdio.h>
#include <conio.h>

#include <api/keyboard.h>
#include <api/wait.h>

int main();

unsigned char enemies[8];
unsigned char tick;

int main() {
    unsigned char x = 0, y = 0;
    unsigned char i;
    unsigned char c;
    unsigned char moved;
    /* state = HELLO; */
    clrscr();

    gotoxy(8, 1);
    puts("W/A/S/D - move, Q - quit");
    gotoxy(8, 2);
    puts("     Press any key");
    if (cgetc() == 'q') {
        puts("\n");
        return 0;
    }

    for (i = 0; i < 8; i++) {
        enemies[i] = -1;
    }
    tick = 0;

    clrscr();
    gotoxy(x, y);
    while (1) {
        c = igetch();
        moved = 0;
        if (c == 'a') {
            x--;
            moved = 1;
        } else if (c == 'd') {
            x++;
            moved = 1;
        } else if (c == 'w') {
            y--;
            moved = 1;
        } else if (c == 's') {
            y++;
            moved = 1;
        } else if (c == 'q') {
        puts("\n");
            return 0;
        }
        tick++;
        for (i = 0; i < 8; i++) {
            if (enemies[i] != 255) {
                enemies[i]--;
            }
        }
        if (tick == 30) {
            tick = 0;
            x++;
            moved = 1;
        }
        if (moved) {
            moved = 0;
            gotoxy(x, y);
        }
        wait16ms();
    }
    /* return 0; */
}
