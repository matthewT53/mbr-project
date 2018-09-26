;
; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Someone from COMP6845
;

[bits 16]
[org 0x0600]

_start:
    cli
    xor ax, ax

    mov ds, ax  ; Set data segment to 0
    mov es, ax  ; extra segment = 0
    mov ss, ax  ; stack segment = 0
    xor sp, sp  ; stack pointer = 0

    mov di, 0x0600      ; new memory addr for this MBR
    mov si, 0x7c00      ; where this MBR is currently at
    mov cx, 0x0100      ; size of the MBR (0x1000 = 512)

    rep movsw                   ; copy the mbr to 0x600
    jmp 0:_wipe_partition       ; jumps to new address starting at 0x600

_wipe_partition:
    sti
    lea di, [PART_1]
    lea si, [PART_4]
    mov cx, 0x10

    rep movsw
    jmp 0:_halt

_halt:
    hlt

mesg_1: db "Wiping partition 1.", 0x00

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x0

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
