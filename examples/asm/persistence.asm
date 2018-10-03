;
;   This code tries to insert a file directly into a FAT32 filesystem.
;   Deleting this file using the filesystem will be impossible
;   Unless the MBR is cleaned.
;

[bits 16]
[org 0x1000]

_start:
    
