#include <stdio.h>
#include <conio.h>
#include <unistd.h>

// https://cc65.github.io/doc/cc65.html
/* #pragma code-name ("PROGRAM") */
/* #pragma rodata-name ("PROGRAM") */

int main();
/* extern void sdcard2_test(); */

/* void foo(char a, char b) { */
    /* char x = 0; */
    /* gotoxy(10, 2); */
    /* while (a < b) { */
    /*     puts("a"); */
    /*     a++; */
    /* } */
    /* for (x = 0; x < 5; x++) { */
    /*     puts("b"); */
    /* } */
    /* puts(" done\n"); */
/* } */

int main() {
    char x;
    puts("Hello from C!\n");
    /* foo(2, 5); */
    /* x = exec("Foo", "bar baz"); */
    /* sdcard2_test(); */
    return 0;
}
