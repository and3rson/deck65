#include <stdio.h>
/* #include <conio.h> */

// https://cc65.github.io/doc/cc65.html
/* #pragma code-name ("PROGRAM") */
/* #pragma rodata-name ("PROGRAM") */

int main();

void foo(char a, char b) {
    /* gotoxy(10, 2); */
    char x = 0;
    while (a < b) {
        puts("a");
        a++;
    }
    for (x = 0; x < 5; x++) {
        puts("b");
    }
    puts(" done\n");
}

int main() {
    puts("Hello from C!\n");
    foo(2, 5);
    return 0;
}
