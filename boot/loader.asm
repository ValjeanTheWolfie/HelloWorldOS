;==================================================
;               The loader program
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

SECTION LOADER vstart=0
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, BASE_ADDRESS_LOADER

    ;----------------------------
    ;    Load GDT Table
    ;----------------------------
    mov ah, 02h
    mov al, HD_SECTOR_CNT_GDT
    mov bx, BASE_ADDRESS_GDT
    mov cx, 0
    mov cl, HD_SECTOR_GDT
    mov dx, 0
    mov dl, 0x80
    int 13h

    ;----------------------------
    ;  Activate Protected Mode
    ;----------------------------
    in al, 0x92
    or al, 10b
    out 0x92, al

    lgdt [GDT_REGISTER_ADDR]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp dword SELECTOR_LOADER: protected_mode_start

    [bits 32]
protected_mode_start:
    mov ax, SELECTOR_LOADER
    mov ds, ax
    mov es, ax
    
    mov ax, SELECTOR_STACK
    mov ss, ax
    mov esp, STACK_TOP_INIT_OFFSET

    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov eax, 0
.loop:
    mov byte [gs:eax], '!'
    inc eax
    mov byte [gs:eax], 0x0f
    inc eax
    cmp eax, 480
    je end
    jmp .loop
end:
    jmp $

