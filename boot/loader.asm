;==================================================
;               The loader program
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

SECTION LOADER vstart=LOADER_BASE_ADDRESS
    jmp loader_start

    ;----------------------------
    ;        GDT table
    ;----------------------------
    align 8
gdt_table_base:
; (MSB)                    - GDT Entry -                      (LSB)
; | 31..............................16 | 15.....................0 |
; |             Base 0:15              |        Limit 0:15        |
; | 63......56 | 55...52 | 51.......48 | 47.......40 | 39......32 |
; | Base 31:24 |  Flags  | Limit 16:19 | Access Byte | Base 16:23 |
    ; 0 - The 1st GDT entry is inaccessible
    dq 0 
    ; 1 - The code segment
    dw (0xFFFF - LOADER_BASE_ADDRESS), LOADER_BASE_ADDRESS,  (GDT_ACCESS_BYTE_CODE << 8),  (GDT_FLAGS_BIYE_32 << 4)
    ; 2 - The heap segment
    dw 0xFFFF, 0, (GDT_ACCESS_BYTE_HEAP << 8) + 0x1, (GDT_FLAGS_BIYE_32 << 4)
    ; 3 - The stack segment
    dw 0xFFFF, 0, (GDT_ACCESS_BYTE_STACK << 8) + 0x3, (GDT_FLAGS_BIYE_32 << 4)
    ; 4 - The video memory segment
    dw 0x7FFF, 0x8000, (GDT_ACCESS_BYTE_HEAP << 8) + 0xb, (GDT_FLAGS_BIYE_32 << 4)
    times (LOADER_GDT_TABLE_SIZE - ($ - gdt_table_base)) db 0
gdtr_register:
    dw LOADER_GDT_TABLE_SIZE
    dd gdt_table_base
    
    SELECTOR_CODE  equ (1 << 3)
    SELECTOR_HEAP  equ (2 << 3)
    SELECTOR_STACK equ (3 << 3)
    SELECTOR_VIDEO equ (4 << 3)

    ;----------------------------
    ;     Message data
    ;----------------------------
    message_loader_start db "Successfully started the loader in real mode.", CR, LF, 0
    message_len_loader_start equ ($ - message_loader_start - 1)

loader_start:
    ;Get cursor position
    mov ah, 03h
    mov bh, 00h
    int 10h
    ;Print a message indicating the start of the loader
    mov bl, 0x0f
    mov cx, message_len_loader_start
    mov ax, message_loader_start
    mov bp, ax
    mov ah, 13H
    mov al, 01b
    int 10h

    ;----------------------------
    ;  Activate Protected Mode
    ;----------------------------
    in al, 0x92
    or al, 10b
    out 0x92, al

    lgdt [gdtr_register]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp dword SELECTOR_CODE: (protected_mode_start - $$)

    ;----------------------------
    ;  Activate Protected Mode
    ;----------------------------
    [bits 32]
protected_mode_start:
    mov ax, SELECTOR_HEAP
    mov ds, ax
    mov es, ax
    
    mov ax, SELECTOR_STACK
    mov ss, ax
    mov esp, LOADER_STACK_ADDRESS

    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov eax, 0
loop:
    mov byte [gs:eax], '!'
    inc eax
    mov byte [gs:eax], 0x0f
    inc eax
    cmp eax, 480
    je end
    jmp loop
end:


    jmp $

print_string:






