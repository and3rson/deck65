#include <stdio.h>
#include <conio.h>

int main();

void foo(char a, char b) {
    char x = 0;
    gotoxy(10, 2);
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