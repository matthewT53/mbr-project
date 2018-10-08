;
;   This bytes generated from this code should be placed in sector 2 of
;   a disk.
;   The custom mbr should call into this code.
;

[bits 16]
[org 0x800]

%define NEW_MBR_ADDR            0x600
%define SECTOR_TWO_ADDR         0x800
%define PART_2_OFFSET           0x1ce

_start:
    pusha
    call _reset_disk

    lea di, [NEW_MBR_ADDR + PART_2_OFFSET]  ; get MBR start address
    mov al, 0x00
    mov cx, 0x10

    rep stosb

    ; write the local copy of the partition onto the disk
    mov al, 0x1                 ; we want to laod one sector
    mov ch, 0x0                 ; cylinder
    mov dh, 0x0                 ; head
    mov cl, 0x1                 ; first sector
    mov bx, NEW_MBR_ADDR
    call _write_sector_chs

    popa
    ret

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _disk_io_error
    ret

_write_sector_chs:
    mov ah, 0x3
    int 0x13
    jc _disk_io_error
    ret

_disk_io_error:
    mov si, disk_io_error_msg
    call _print_str
    jmp _end_loop

_print_str:
    lodsb
    or al, al               ; did we reach a null byte?
    jz _print_end
    mov ah, 0xe
    int 0x10
    jmp _print_str

_print_end:
    ret

_end_loop:                  ; after printing an error, we should just loop forever
    jmp _end_loop

disk_io_error_msg:          db "[XOR] Disk IO error!", 0x0a, 0x00
