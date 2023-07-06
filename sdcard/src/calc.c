#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

#include <api/types.h>
#include <api/lcd.h>

int main(int argc, char **argv);

byte stack[16];
byte *stackPtr = stack;

void push(byte b) {
    *(stackPtr++) = b;
}

byte pop() {
    return *(--stackPtr);
}

int main(int argc, char **argv) {
    char *s, c;
    byte i = 0;
    byte v;
    while (i < argc) {
        s = argv[i];
        c = s[0];
        if (c == '+') {
            push(pop() + pop());
        } else if (c == '-') {
            v = pop();
            push(pop() - v);
        } else if (c == '*') {
            push(pop() * pop());
        } else if (c == '/') {
            v = pop();
            push(pop() / v);
        } else {
            push(atoi(s));
        }
        i++;
    }
    puts("Result: ");
    printhex(*(--stackPtr));
    cputc('\n');
    return 0;
}
