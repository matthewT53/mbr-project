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

    mov di, 0x0600   ; new memory addr for this MBR
    mov si, 0x7c00  ; where this MBR is currently at
    mov cx, 0x0100  ; size of the MBR (0x1000 = 512)

    rep movsw

    xor ax, ax
