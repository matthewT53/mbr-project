;
;   This code tries to insert a file directly into a FAT32 filesystem.
;   Deleting this file using the filesystem will be impossible
;   Unless the MBR is cleaned.
;

[bits 16]
[org 0x800]

%define SECTOR_TWO_ADDR     0x800
%define NEW_MBR_ADDR        0x600
%define FAT32_VBR_ADDR      0x1000

_start:
    pusha

_scan_for_fat:
    

_end:
    popa

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _disk_io_error
    ret

_read_sector_chs:
    mov ah, 0x2
    int 0x13
    jc _disk_io_error
    ret

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _disk_io_error
    ret
