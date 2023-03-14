#!/usr/bin/env python3

from dataclasses import dataclass
from math import ceil
import os
from struct import unpack

import click

SEC = 512  # Sector size


@dataclass
class DirEntry:
    F_RDONLY = 1
    F_HIDDEN = 2
    F_SYSTEM = 4

    filename: str
    ext: str
    attr: int
    _nt_res: int
    creation: int
    creation_t: int
    creation_d: int
    last_access_d: int
    _fat32_res: int
    last_write_t: int
    last_write_d: int
    first_cluster: int
    size: int

    @property
    def is_system(self):
        return self.attr & DirEntry.F_SYSTEM


@click.command()
@click.argument("device")
def list(device):
    with open(device, "rb") as dev:
        mbr = dev.read(SEC)
        bootsect_sec = unpack("<H", mbr[0x1C6:0x1C8])[0]
        print("FAT bootsector:", bootsect_sec)

        dev.seek(bootsect_sec * SEC)
        bootsect = dev.read(SEC)
        sec_per_cluster, reserved_count, fat_count, root_dir_entries = unpack(
            "<BHBH", bootsect[0x00D:0x013]
        )
        sec_per_fat = unpack("<H", bootsect[0x016:0x018])[0]
        print("Reserved sectors:", reserved_count)
        print("FAT count:", fat_count)
        print("Sectors per FAT:", sec_per_fat)
        print("Root dir entries:", root_dir_entries)
        print("Sectors per cluster:", sec_per_cluster)
        fat_sec = bootsect_sec + reserved_count
        root_dir_sec = fat_sec + fat_count * sec_per_fat
        print("Root dir sector:", root_dir_sec)

        entries = []
        dev.seek(root_dir_sec * SEC)
        for i in range(root_dir_entries):
            entry = DirEntry(*unpack("8s3sBBBHHHHHHHI", dev.read(32)))
            if entry.filename[0] == 0:
                break
            if entry.is_system:
                continue
            entries.append(entry)
            print(entry)
            # print(dev.read(512))
            # dev.seek(SEC, os.SEEK_CUR)

        data_sec = ceil(root_dir_sec + root_dir_entries * 32 / 512)
        print('Data sector:', data_sec)

        # Read first file
        entry = entries[0]
        # Get sector chain
        # first_sector = entry.first_cluster * 2
        current_cluster = entry.first_cluster
        clusters = []
        while current_cluster != 0xFFFF:
            clusters.append(current_cluster)
            dev.seek(fat_sec * SEC + current_cluster * 2)
            current_cluster = unpack('<H', dev.read(2))[0]

        # print(sectors)

        remaining = entry.size
        for cluster in clusters:
            print('Read cluster', cluster)
            # dev.seek(bootsect_sec * SEC + sector * SEC)
            # dev.seek(root_dir_sec * SEC + root_dir_entries * 32 + sector * SEC)
            # dev.seek(root_dir_sec * SEC)
            # dev.seek(root_dir_sec * SEC + root_dir_entries * 32)
            dev.seek((data_sec + (cluster - 2) * sec_per_cluster) * SEC)
            data = dev.read(SEC * sec_per_cluster)
            remaining -= SEC * sec_per_cluster
            if remaining < 0:
                data = data[0:remaining]
            print(data)
        # dev.seek(fat_sec * SEC + entry.first_cluster * 2)  # Does cluster == sector here? Check sectors-per-cluster
        # print(dev.read(512))


if __name__ == "__main__":
    list()
