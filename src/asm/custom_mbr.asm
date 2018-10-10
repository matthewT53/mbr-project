;
;   This file contains a custom bootloader that loads sector 2 from disk
;   and then jumps to it.
;
;   Useful if you want to execute code before jumping into the bootable OS.
;

[bits 16]
[org 0x600]

%define NEW_MBR_ADDR            0x600
%define VBR_ADDR                0x7c00
%define SECTOR_TWO_ADDR         0x800
%define TOP_OF_STACK            0x7c00
%define START_VBR_LBA_OFFSET    0x8

_start:
    cli
    xor ax, ax

    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; extra segment = 0
    mov ss, ax                  ; stack segment = 0

    mov sp, TOP_OF_STACK

    ; copy the mbr to another location
    mov di, NEW_MBR_ADDR
    mov si, 0x7c00
    mov cx, 0x200

    rep movsb

    jmp 0:_scan_partitions

_load_sector_two:
    call _reset_disk
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x2                 ; sector to read from
    mov bx, SECTOR_TWO_ADDR     ; where to store the sector we read
    call _read_sector_chs

    call 0:SECTOR_TWO_ADDR
    ret

_scan_partitions:
    sti
    mov [drive_type], dl
    mov si, welcome_msg
    call _print_str

    ; loads the second sector and then jumps into it
    call _load_sector_two

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
    mov dl, BYTE [drive_type]
    mov WORD [part_offset], bx

    call _reset_disk

_check_extensions:
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    jc _read_with_chs

    ; construct the DAP packet
    mov bx, WORD [part_offset]
    mov esi, DWORD [bx + START_VBR_LBA_OFFSET]
    
    push DWORD 0x0
    push esi

    push 0x0
    push VBR_ADDR

    push 0x1
    push 0x10

    mov si, sp

_read_with_lba:
    call _read_sector_lba
    add sp, 0x10

    jmp _verify_vbr

_read_with_chs:
    mov bp, WORD [part_offset]
    mov al, 0x1                     ; we want to read one sector
    mov dh, BYTE [bp + 0x1]         ; head
    mov ch, BYTE [bp + 0x2]         ; cylinder
    mov cl, BYTE [bp + 0x3]         ; sector
    mov bx, VBR_ADDR                ; addr to store the VBR
    call _read_sector_chs

_verify_vbr:
    cmp WORD [VBR_ADDR + 0x1fe], 0xaa55
    jne _read_wrong_sector_error

_jump_vbr:
    mov si, bx
    xor dh, dh
    ; jump to the VBR
    jmp 0:VBR_ADDR

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

_write_sector:
    mov ah, 0x3
    int 0x13
    jc _disk_io_error
    ret
                                ; some error handling
_no_os_error:
    mov si, no_os_error_msg
    call _print_str
    jmp _end_loop

_read_wrong_sector_error:
    mov si, wrong_sector_msg
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

welcome_msg:                db "My very own MBR!", 0x0d, 0x0a, 0x00
wrong_sector_msg:           db "Read wrong sector, not a VBR!", 0x0d, 0x0a, 0x00
no_os_error_msg:            db "No operating system found!", 0x0d, 0x0a, 0x00
disk_io_error_msg:          db "Disk IO error!", 0x0d, 0x0a, 0x00

drive_type:                 db 0x00
part_offset:                dw 0x0000

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
