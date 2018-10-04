[bits 16]
[org 0x1000]

%define NEW_MBR_ADDR        0x1000
%define TOP_OF_STACK        0x0600
%define READ_SECTOR_ADDR    0x0800

_start:
    cli
    xor ax, ax

    mov es, ax
    mov ds, ax
    mov ss, ax

    mov sp, TOP_OF_STACK

    ; save the drive type
    mov [drive_type], dl

    ; copy the mbr to a new location
    mov di, NEW_MBR_ADDR
    mov si, 0x7c00
    mov cx, 0x200

    rep movsb

    jmp 0:_read_lba

_read_lba:
    ; setup the DAP
    push 0x0
    push 0x0
    push 0x0
    push 0x0

    push 0x0
    push READ_SECTOR_ADDR

    push 0x1
    push 0x10

    mov si, sp
    mov dl, 0x80
    call _read_sector_lba
    hlt

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _disk_io_error
    ret

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

drive_type:             db 0x00
disk_io_error_msg:      db "Failed to read sector!", 0x00

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
