;
;   This code loads 2nd sector of disk into memory and then jumps to it.
;

[bits 16]
[org 0x0600]

_start:
    call _reset_disk

    mov al, 0x1
    mov ch, 0x0
    mov dh, 0x0
    mov cl, 0x2
    mov bx, 0x2000
    call _read_sector
    ret

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _reset_error
    ret

_read_sector:
    mov ah, 0x2                 ; code for specifying reading sectors
    int 0x13
    jc _read_error
    ret
