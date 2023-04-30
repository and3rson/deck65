#include <stdio.h>
#include <conio.h>

#include <api/types.h>
#include <api/lcd.h>

int main(int argc, char **argv);

/* extern byte argc; */
/* extern char *argv[16]; */

int main(int argc, char **argv) {
    char i;
    puts("Arg count: ");
    printhex(argc);
    puts("\nArgs: ");
    for (i = 0; i < argc; i++) {
        if (i) {
            puts(", ");
        }
        puts(argv[i]);
    }
    cputc('\n');
    return 0;
}
