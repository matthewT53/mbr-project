;
; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Someone from COMP6845
;

[bits 16]
[org 0x0600]

%define sector_storage 0x1000

_start:
    cli
    xor ax, ax

    mov ds, ax                  ; Set data segment to 0
    mov es, ax                  ; extra segment = 0
    mov ss, ax                  ; stack segment = 0
    xor sp, sp                  ; stack pointer = 0

    mov sp, 0x100

    mov di, 0x0600              ; new memory addr for this MBR
    mov si, 0x7c00              ; where this MBR is currently at
    mov cx, 0x0100              ; size of the MBR (0x100 = 256) but we are writing words

    rep movsw                   ; copy the mbr to 0x600
    jmp 0:_wipe_partition       ; jumps to new address starting at 0x600

_wipe_partition:
    lea di, [PART_1]
    lea si, [PART_4]
    mov cx, 0x10

    rep movsb
    call _read_sector
    hlt

_read_sector:
    pusha
    mov al, 0x5                 ; # sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov cl, 0x1                 ; sector to read from
    mov dh, 0x00                ; head to read from
    mov dl, 0x00                ; read from the first hard drive
    mov ax, sector_storage      ; where to store sectors we read
    mov es, ax
    mov bx, 0
    mov ah, 0x2                 ; code for specifying read sector
    int 0x13
    popa
    ret

_error_read:
    jmp 0:_halt

_halt:
    hlt

mesg_1: db "Wiping partition 1.", 0x00
mesg_2: db "Error reading sector.", 0x00

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
