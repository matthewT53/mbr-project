;
;   This code demonstrates how to write to disk in LBA mode.
;   Written by: A guy in COMP6845
;

[bits 16]
[org 0x600]

%define RELOCATED_ADDR  0x600
%define DATA_ADDR        0x800

%define SECTOR_SIZE     0x200

_start:
    cli
    xor ax, ax

    mov es, ax
    mov ds, ax
    mov ss, ax

    mov si, 0x7c00
    mov di, RELOCATED_ADDR
    mov cx, SECTOR_SIZE

    rep movsb

    jmp 0:_read_with_lba

_read_with_lba:
    push DWORD 0x0
    push DWORD 0x1          ; read from sector 1

    push 0x0
    push DATA_ADDR

    push 0x1
    push 0x10

    mov si, sp
    call _read_sector_lba
    add sp, 0x10

_write_with_lba:
    mov si, welcome_msg
    call _print_str

    push DWORD 0x0
    push DWORD 0x4          ; write to sector 4

    push 0x0
    push DATA_ADDR

    push 0x1
    push 0x10

    mov si, sp
    xor eax, eax
    call _write_sector_lba
    add sp, 0x10
    jmp _end

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _disk_error
    ret

_write_sector_lba:
    mov ah, 0x43
    int 0x13
    jc _disk_error
    ret

_disk_error:
    mov si, disk_error_msg
    call _print_str
    jmp _end

_print_str:
    lodsb
    or al, al           ; did we reach a null byte?
    jz _print_end
    mov ah, 0xe
    int 0x10
    jmp _print_str

_print_end:
    ret

_end:
    jmp _end

welcome_msg:    db "Trying to write using LBA!", 0x0d, 0x0a, 0x00
disk_error_msg: db "Error reading/writing to disk!", 0x0d, 0x0a, 0x00

times 0x1be - ($ - $$) db 0x00

PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

dw 0xaa55
