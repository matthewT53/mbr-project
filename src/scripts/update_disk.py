#!/usr/bin/python

MBR_FILENAME    = "../bin/boot.bin"
DISK_FILENAME   = "../bochsdbg/disk.img"
SECTOR_SIZE     = 512

def update_disk():
    mbr_fp = open(MBR_FILENAME, "rb")
    mbr = mbr_fp.read()
    mbr_fp.close()

    # generate some dummy sectors
    extra_sectors = "a" * SECTOR_SIZE
    extra_sectors += "b" * SECTOR_SIZE
    extra_sectors += "c" * SECTOR_SIZE
    extra_sectors += "d" * SECTOR_SIZE
    extra_sectors += "e" * SECTOR_SIZE

    buf = mbr + extra_sectors

    disk_fp = open(DISK_FILENAME, "r+b")
    disk_fp.write(buf)
    disk_fp.close()
    return True


# Main program starts here
if update_disk():
    print "Successfully updated disk!"
else:
    print "Something possibly went wrong!"
