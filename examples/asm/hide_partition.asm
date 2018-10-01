;
; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Your boss from COMP6845
;

[bits 16]
[org 0x1000]

%define SECTOR_READ_ADDR    0x1500
%define STACK_ADDR          0x600

_start:
    cli
    xor ax, ax

    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; extra segment = 0
    mov ss, ax                  ; stack segment = 0

    mov sp, STACK_ADDR

    mov di, 0x1000              ; new memory addr for this MBR
    mov si, 0x7c00              ; where this MBR is currently at
    mov cx, 0x0100              ; size of the MBR (0x100 = 256) but we are writing words

    rep movsw                   ; copy the mbr to 0x1000
    jmp 0:_read_disk            ; jumps to new address starting at 0x600

_read_disk:
    call _reset_disk

    mov si, reading_disk_msg
    call _print_str

    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x2                 ; sector to read from
    mov bx, SECTOR_READ_ADDR    ; where to store the sector we read
    call _read_sector

    mov cl, 0x4
    call _write_sector

    mov cl, 0x5
    call _write_sector

    mov cl, 0x6
    call _write_sector
    
    hlt

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

_write_sector:
    mov ah, 0x3
    int 0x13
    jc _write_error
    ret

_write_error:
    mov si, write_error_msg
    call _print_str
    hlt

_reset_error:
    mov si, reset_disk_error_msg
    call _print_str
    hlt

_read_error:
    mov si, read_disk_error_msg
    call _print_str
    hlt

_print_str:
    lodsb
    or al, al
    jz _print_end
    mov ah, 0xe
    int 0x10
    jmp _print_str

_print_end:
    ret

reading_disk_msg:           db "Reading sector 1 of disk!", 0x00
reset_disk_error_msg:       db "Error resetting disk.", 0x00
read_disk_error_msg:        db "Error reading sector.", 0x00
write_error_msg:            db "Error writing sector.", 0x00

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
