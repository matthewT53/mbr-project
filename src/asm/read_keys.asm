; Our code
org 0x7C00                      ; BIOS loads our program at this address
bits 16                         ; We're working at 16-bit mode here

section .text
    global _start
_start:

loop0:  
	cli                  
	mov  ax, 0              
        int  16h		; get_key interrupt 
	
	mov dl, al		; get_key places next keypress into al
	mov [buf], dl		; move char entered by user into buf
	 
	mov si, buf             ; SI now points to our message
	mov ah, 0x0E            ; Indicate BIOS we're going to print chars
.loop	lodsb                   ; Loads SI into AL and increments SI [next char]
	or al, al               ; Checks if the end of the string
	jz loop0                ; Jump back to the main loop
	int 0x10                ; Otherwise, call interrupt for printing the char
	jmp .loop               ; Next iteration of the loop

buf:    db 0           ; 1-byte buffer to write keypresses to

; Magic numbers
times 510 - ($ - $$) db 0
dw 0xAA55
