#!/usr/bin/python

# this script extends the bootloader to have more sectors.

SECTOR_SIZE = 512

buf  = "a" * SECTOR_SIZE
buf += "b" * SECTOR_SIZE
buf += "c" * SECTOR_SIZE
buf += "d" * SECTOR_SIZE
buf += "e" * SECTOR_SIZE

f = open("../bin/boot.bin", "rb")
mbr = f.read()
f.close()

fp_disk = open("../bin/disk.bin", "wb")
fp_disk.write(mbr)
fp_disk.write(buf)
fp_disk.close()
