;==================================================
;               The loader program
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

SECTION LOADER vstart=LOADER_BASE_ADDRESS
    ;Get cursor position
    mov ah, 03h
    mov bh, 00h
    int 10h
    ;Print a message indicating the start of the loader
    mov bl, 0x0f
    mov cx, loader_start_message_len
    mov ax, loader_start_message
    mov bp, ax
    mov ah, 13H
    mov al, 01b
    int 10h

    jmp $

    loader_start_message db "Successfully entered the loader.", CR, LF, 0
    loader_start_message_len equ ($ - loader_start_message - 1)

