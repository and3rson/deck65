#!/usr/bin/env python3
# Source: https://github.com/YulienPohl/GAL16V8/blob/main/jedec2hex.py
from bitarray import bitarray
from bitarray.util import ba2hex
import re
import argparse

FUSES_PATTERN = re.compile(r"\*?L(\d+)\s(\d+)")

# GAL16v8 address space
# https://k1.spdns.de/Develop/Projects/GalAsm/info/galer/jedecfile.html
AND = 0000, 2047  # matrix of fuses (AND-array)
XOR = 2048, 2055  # XOR bits
SIG = 2056, 2119  # signature
AC1 = 2120, 2127  # AC1 bits
PE = 2128, 2191  # product term disable bits
SYN = 2192  # SYN bit
AC0 = 2193  # AC0 bit

parser = argparse.ArgumentParser(description="Converts GAL16V8 JEDEC to hex")
parser.add_argument("-i", dest="in_file", required=True)
parser.add_argument("-o", dest="out_file", required=True)
args = parser.parse_args()

with open(args.in_file, "r") as f_in, open(args.out_file, "w+") as f_out:
    f_out.write("v2.0 raw\n")

    p_addr = 0
    data_len = 0
    fuses_bin = bitarray()
    for line in f_in:
        fuses_match = FUSES_PATTERN.match(line)
        if fuses_match:
            addr, data = fuses_match.groups()
            c_addr = int(addr)

            d_addr = c_addr - p_addr - data_len
            p_addr = c_addr
            data_len = len(data)

            # empty fuse address
            if d_addr > 0:
                fuses_bin += d_addr * bitarray("1")

            fuses_bin += bitarray(data)

    # ignore PE & SIG
    del fuses_bin[PE[0] : PE[1] + 1]
    del fuses_bin[SIG[0] : SIG[1] + 1]

    # 32 bit padding
    padding = 32 - len(fuses_bin) % 32
    fuses_bin += padding * bitarray("1")
    fuses_hex = ba2hex(fuses_bin)

    # write 8 hex per line
    for i in range(0, len(fuses_hex), 8):
        f_out.write(fuses_hex[i : i + 8] + "\n")
