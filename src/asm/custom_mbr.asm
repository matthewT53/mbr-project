;
;   This file contains a custom bootloader that loads sector 2 from disk
;   and then jumps to it.
;
;   Useful if you want to execute code before jumping into the bootable OS.
;

[bits 16]
[org 0x1000]

%define NEW_MBR_ADDR            0x1000
%define VBR_ADDR                0x1200
%define SECTOR_TWO_ADDR         0x1400
%define TOP_OF_STACK            0x2500
%define START_VBR_LBA_OFFSET    0x8

_start:
    cli
    xor ax, ax

    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; extra segment = 0
    mov ss, ax                  ; stack segment = 0

    mov sp, TOP_OF_STACK
    push dx                     ; push dl onto the stack

    ; copy the mbr to another location
    mov di, NEW_MBR_ADDR
    mov si, 0x7c00
    mov cx, 0x200

    rep movsb

    ;call _load_sector_two

    jmp 0:_scan_partitions

_load_sector_two:
    call _reset_disk
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x2                 ; sector to read from
    mov bx, SECTOR_TWO_ADDR     ; where to store the sector we read
    call _read_sector
    ret

_scan_partitions:
    sti

_check_partition:
    mov bx, PART_1
    mov cx, 0x4

_loop:
    mov al, BYTE [bx]
    cmp al, 0x80
    jz _found_os
    add bx, 0x10
    dec cx
    jz _no_os_error
    jmp _loop

_found_os:
    pop dx

    ; construct the DAP packet
    ; there is probably a better way to do this
    ; cant figure out how to push 4-bytes or 8 bytes
    ; TODO: The code below will not work!
    mov esi, DWORD [bx + START_VBR_LBA_OFFSET]
    push DWORD 0x0
    push esi

    push 0x0
    push VBR_ADDR

    push 0x1
    push 0x10

    mov si, sp

    ; we want to allign the stack
    ;push 0x0
    call _read_sector_lba

    ; jump to the VBR
    jmp 0:VBR_ADDR

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _disk_io_error
    ret

_read_sector:
    mov ah, 0x2                 ; code for specifying reading sectors
    int 0x13
    jc _disk_io_error
    ret

_write_sector:
    mov ah, 0x3
    int 0x13
    jc _disk_io_error
    ret

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _disk_io_error
    ret

_no_os_error:
    mov si, no_os_error_msg
    call _print_str
    hlt

_disk_io_error:
    mov si, disk_io_error_msg
    call _print_str
    hlt

_print_str:
    lodsb
    or al, al           ; did we reach a null byte?
    jz _print_end
    mov ah, 0xe
    int 0x10
    jmp _print_str

_print_end:
    ret

no_os_error_msg:            db "No operating system found!", 0x00
disk_io_error_msg:          db "Disk IO error!", 0x00

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: db 0x80, 0x20, 0x21, 0x00, 0x07, 0xfe, 0xff, 0xff, 0x00, 0x08, 0x00, 0x00, 0x00, 0x30, 0x22, 0x07
PART_2: db 0x00, 0xfe, 0xff, 0xff, 0x0c, 0xfe, 0xff, 0xff, 0x00, 0x38, 0x22, 0x07, 0x00, 0xb8, 0x5d, 0x00
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
