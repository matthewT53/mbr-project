#!/usr/bin/python

#
# Overwriting the default windows mbr with a custom one will not work
# since there are data bytes on the default mbr that need to be copied over
#

DEFAULT_WINDOWS_MBR = "../bin/vm_mbr.bin"
CUSTOM_MBR          = "../bin/boot.bin"
RESULT_FILE         = "../bin/mbr_fixed.bin"

def fix_mbr():
    fp_1 = open(CUSTOM_MBR, "rb")
    fp_2 = open(DEFAULT_WINDOWS_MBR, "rb")

    buf1     = fp_1.read(0x1b2)

    fp_2.seek(0x1b2, 0)
    buf2    = fp_2.read()

    fp_1.close()
    fp_2.close()

    buf = buf1 + buf2

    fp = open(RESULT_FILE, "wb")
    fp.write(buf)
    fp.close()
    return True

#
# Main program starts here.
#

if fix_mbr():
    print "Successfully fixed the custom mbr at:" + CUSTOM_MBR
    print "Wrote the fixed version to: " + RESULT_FILE
else:
    print "Failed to fix the custom mbr at: " + CUSTOM_MBR
