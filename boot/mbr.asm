;==================================================
;  The loading program for the Master Boot Record
;--------------------------------------------------
; 2020.3.28  ValjeanTheWolfie  Create
;==================================================
%include 'commondefs.asm'

SECTION LOADER vstart=0x7c00
    ;Initialize the segment registers using the values in CS
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ;Initialize the stack pointer register
    mov sp, 0x7c00

    ;clear the screen
    ; mov ax, 0x600
    ; mov bx, 0x700
    ; mov cx, 0
    ; mov dx, 0x184f
    ; int 10h

    ;get cursor position
    mov ah, 3
    mov bh, 0
    int 10h

    ;Call the BIOS interrupt to display the message on the screen
    mov ax, message
    mov bp, ax
    
    mov cx, msgLen
    mov ah, 0x13
    mov al, 0x01
    mov bl, 0x0f

    int 10h

    jmp $


    message db "Yeah! The boot loader program has been successfully executed!!", CR, LF, 0
    msgLen equ ($ - message - 1)


    times 510 - ($ - $$) db 0
    dw 0xaa55