#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>

#include <api/types.h>

extern byte fat16_opendir();
extern byte fat16_readdir();
extern fat_entry_t *fat16_direntry();

int cmd_ls(int argc, char **argv) {
    byte err, i = 0, k;
    fat_entry_t *entry;
    char buff[20];
    if ((err = fat16_opendir())) {
        return err;
    }
    while ((err = fat16_readdir()) != 1) {
        if (err) {
            return err;
        }
        entry = fat16_direntry();
        /* strncpy(buff, entry->filename, 8); */
        /* buff[8] = '.'; */
        /* strncpy(buff + 9, entry->ext, 3); */
        /* buff[12] = ' '; */
        /* itoa(entry->size, buff + 13, 10); */
        /* /1* for (k = 0; k < 20; *1/ */
        /* k = 12; */
        /* while(buff[++k]); */
        /* while(k < 20) { */
        /*     buff[k++] = ' '; */
        /* } */
        /* buff[k] = 0; */
        /* puts(buff); */
        /* if (++i % 2 == 0) { */
        /*     cputc('\n'); */
        /* } */

        strncpy(buff, entry->filename, 8);
        buff[8] = '.';
        strncpy(buff + 9, entry->ext, 3);
        buff[12] = ' ';
        buff[13] = 0;
        puts(buff);
        if (++i % 3 == 0) {
            cputc('\n');
        }
    }
    if (i % 3) {
        cputc('\n');
    }
    /* if (i % 2) { */
    /*     cputc('\n'); */
    /* } */
    return 0;
}
