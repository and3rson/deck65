#!/usr/bin/env python3

import click
from struct import unpack

SEC = 512  # Sector size


@click.command()
@click.argument("device")
def list(device):
    with open(device, 'rb') as dev:
        mbr = dev.read(SEC)
        bootsect_sec = unpack('<H', mbr[0x1C6:0x1C8])[0]
        print('FAT bootsector:', bootsect_sec)

        dev.seek(bootsect_sec * SEC)
        bootsect = dev.read(SEC)
        reserved_count, fat_count = unpack('<HB', bootsect[0x00E:0x011])
        sec_per_fat = unpack('<H', bootsect[0x016:0x018])[0]
        print('Reserved sectors:', reserved_count)
        print('FAT count:', fat_count)
        print('Sectors per FAT:', sec_per_fat)
        root_dir_sec = bootsect_sec + reserved_count + fat_count * sec_per_fat
        print('Root dir sector:', root_dir_sec)

        dev.seek(root_dir_sec * SEC)
        print(dev.read(512))


if __name__ == '__main__':
    list()
