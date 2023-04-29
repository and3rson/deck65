#include <stdio.h>
#include <conio.h>
#include <string.h>

#include <api/types.h>
#include <api/lcd.h>

extern void sdc_select_sector(int sector);
extern byte sdc_read_sector(byte* dest);
extern byte sdc_read_block_start(int offset);
extern byte sdc_read_block_byte();
extern word sdc_read_block_word();
extern void sdc_read_block_end();

word bootsec;

byte sec_per_clu;
word res_sec_count;
byte fat_count;
word root_dir_entries;
word sec_per_fat;

word fat_sec;
word root_dir_sec;
word root_dir_sec_count;
word data_sec;

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

union sector {
    fat_entry_t entries[16];
    byte data[512];
    word wdata[256];
} sector;

fat_entry_t fd;
word cluster;

byte fat16_init() {
    byte err, i;
    int ii;
    word sig;

    // Find boot sector
    if ((err = sdc_read_block_start(0))) {
        return err;
    }
    for (ii = 0; ii < 0x1C6; ii++) { // Skip to $1C6
        sdc_read_block_byte();
    }
    bootsec = sdc_read_block_word();
    for (i = 0; i < 56; i++) {
        sdc_read_block_byte();
    }
    sdc_read_block_end();

    // Read boot sector
    if ((err = sdc_read_block_start(bootsec))) {
        return err;
    }
    for (i = 0; i < 0x0D; i++) { // Skip to $0D
        sdc_read_block_byte();
    }
    sec_per_clu = sdc_read_block_byte();      // $0D
    res_sec_count = sdc_read_block_word();    // $0E..$0F
    fat_count = sdc_read_block_byte();        // $10
    root_dir_entries = sdc_read_block_word(); // $11..$12
    sdc_read_block_byte();                    // $13
    sdc_read_block_byte();                    // $14
    sdc_read_block_byte();                    // $13
    sec_per_fat = sdc_read_block_word();      // $16..$17
    for (ii = 0; ii < 486; ii++) {            // Skip remaining 486 bytes (256+232-2)
        sdc_read_block_byte();
    }
    sig = sdc_read_block_word();
    if (sig != 0xAA55) {
        /* puts("Incorrect bootsector signature: "); */
        /* printword(sig); */
        /* cputc('\n'); */
        return 0xF1;
    }
    sdc_read_block_end();

    /* puts("SPC="); */
    /* printhex(sec_per_clu); */
    /* puts(" RSC="); */
    /* printword(res_sec_count); */
    /* puts(" FC="); */
    /* printhex(fat_count); */
    /* puts(" RDE="); */
    /* printword(root_dir_entries); */
    /* puts(" SPF="); */
    /* printword(sec_per_fat); */
    /* cputc('\n'); */

    if (sec_per_clu != 1) {
        // Geometry unsupported, can handle only 1 sector per cluster
        return 0xF2;
    }

    fat_sec = bootsec + res_sec_count;
    root_dir_sec = fat_sec + sec_per_fat * fat_count;
    root_dir_sec_count = root_dir_entries >> 4; // * 32 / 512
    data_sec = root_dir_sec + root_dir_sec_count;

    puts("FAT16: RDS=");
    printword(root_dir_sec);
    puts(" RDSC=");
    printword(root_dir_sec_count);
    puts(" DS=");
    printword(data_sec);
    cputc('\n');

    return 0;
}

/*
 * fat16_open - find & open file
 *
 * returns: 0 on success
 */
byte fat16_open(const char* filename) {
    byte err, k;
    word ii, sec = root_dir_sec;
    fat_entry_t* entry;
    for (ii = 0; ii < root_dir_entries; ii++) {
        k = ii % 16;
        if (!k) { // 16 entries per sector
            sdc_select_sector(sec++);
            if ((err = sdc_read_sector(sector.data))) {
                return err;
            }
        }
        entry = &sector.entries[k];
        if (entry->filename[0] == 0) {
            // End of directory
            break;
        }
        if (entry->attr == 0x0F) {
            // LFN entry, skip
            continue;
        }
        /* for (i = 0; i < 8; i++) { */
        /*     cputc(entry->filename[i]); */
        /* } */
        /* cputc('.'); */
        /* for (i = 0; i < 3; i++) { */
        /*     cputc(entry->ext[i]); */
        /* } */
        /* puts("  A="); */
        /* printhex(entry->attr); */
        /* puts(" S="); */
        /* printword(entry->size & 0xFFFF); */
        /* cputc('\n'); */
        // TODO: filename comparison
        if (!strnicmp(filename, entry->filename, strlen(filename))) {
            memcpy(&fd, entry, sizeof(fat_entry_t));
            cluster = entry->first_cluster;
            return 0;
        }
        /* sector.entries[k].filename */
    }
    return 0xF1;
}

/*
 * fat16_read - read next file sector into memory (512 bytes)
 *
 * returns: 0 on success, 1 on eof
 */
byte fat16_read(byte* dest) {
    byte err;
    /* puts("Read sec: "); */
    /* printword(cluster); */
    /* cputc('\n'); */
    sdc_select_sector(data_sec + cluster - 2); // Calculate effective sector
    if ((err = sdc_read_sector(dest))) {
        return err;
    }
    // Find next sector
    sdc_select_sector(fat_sec);
    if ((err = sdc_read_sector(sector.data + (cluster >> 8)))) {
        return err;
    }
    cluster = sector.wdata[cluster & 0xFF];
    if (cluster == 0xFFFF) {
        // EOF
        return 1;
    }
    return 0;
}
