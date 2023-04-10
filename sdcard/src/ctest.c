#include <stdio.h>
/* #include <conio.h> */

// https://cc65.github.io/doc/cc65.html
#pragma code-name ("PROGRAM")
#pragma rodata-name ("PROGRAM")
#pragma bss-name ("PROGRAM")

void foo(unsigned char a, unsigned char b) {
    /* gotoxy(10, 2); */
    int i;
    /* while (a < b) { */
    for (i = 0; i < 5; i++) {
        puts("Test");
        /* a++; */
    }
    puts("\n");
    /* for (x = 0; x < 5; x++) { */
    /*     puts("11"); */
    /* } */
    /* puts("asd\n"); */
}

void main() {
    puts("Hello from C!\n");
    foo(2, 5);
}
