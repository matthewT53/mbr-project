;
; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Your boss from COMP6845
;

[bits 16]
[org 0x1000]

%define SECTOR_READ_ADDR    0x1500
%define STACK_ADDR          0x0500

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

    rep movsw                   ; copy the mbr to 0x600
    jmp 0:_reset_disk           ; jumps to new address starting at 0x600

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk

    call _read_sector
    hlt

_read_sector:
    push bx
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x00                ; head to read from
    mov cl, 0x2                 ; sector to read from
    mov bx, SECTOR_READ_ADDR    ; where to store the sector we read
    mov ah, 0x2                 ; code for specifying reading sectors
    int 0x13
    pop bx
    ret

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
