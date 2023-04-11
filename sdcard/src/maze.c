#include <stdio.h>
#include <conio.h>

// https://cc65.github.io/doc/cc65.html
/* #pragma code-name ("PROGRAM") */
/* #pragma rodata-name ("PROGRAM") */

int main();

extern char igetch();

int main() {
    char x = 0, y = 0;
    char c;
    char moved;
    clrscr();

    if (0) {
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
        gotoxy(1, 2);
    }

    gotoxy(8, 1);
    puts("W/A/S/D - move, Q - quit");
    gotoxy(8, 2);
    puts("     Press any key");
    if (cgetc() == 'q') {
        return 0;
    }

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
            return 0;
        }
        if (moved) {
            gotoxy(x, y);
        }
    }
    return 0;
}
