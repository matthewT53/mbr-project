;
;   This file contains a custom bootloader that loads sector 2 from disk
;   and then jumps to it.
;
;   Useful if you want to execute code before jumping into the bootable OS.
;

[bits 16]
[org 0x1000]

%define NEW_MBR_ADDR        0x1000
%define VBR_ADDR            0x1200
%define SECTOR_TWO_ADDR     0x1400
%define TOP_OF_STACK        0x1600

_start:
    cli
    xor ax, ax

    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; extra segment = 0
    mov ss, ax                  ; stack segment = 0

    mov sp, TOP_OF_STACK
    push dl                     ; push dl onto the stack

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
    mov al, BYTE [PART_1]
    cmp al, 0x80
    jz _found_os
    add bx, 0x10
    dec cx
    jz _no_os_error

_found_os:
    ; construct the DAP packet 
    mov ax, [bx + 11]
    push ax
    mov ax, [bx + 10]
    push ax
    mov ax, [bx + 9]
    push ax
    mov ax, [bx + 8]
    push ax

    push 0x0
    push VBR_ADDR

    push 0x1
    push 0x10

    mov si, sp

    ; we want to allign the stack
    push 0x0
    call _read_sector_lba

    ; jump to the VBR


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
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
