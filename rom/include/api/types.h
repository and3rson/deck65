#ifndef TYPES_H
#define TYPES_H

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;

typedef struct {
    char filename[8];
    char ext[3];
    byte attr;
    byte _res_nt;
    byte creation;
    word creation_time;
    word creation_date;
    word last_access_date;
    word _res_fat32;
    word write_time;
    word write_date;
    word first_cluster;
    dword size;
} fat_entry_t;

#endif
