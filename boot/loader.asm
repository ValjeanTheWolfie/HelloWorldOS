;==================================================
;               The loader program
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

SECTION LOADER vstart=BASE_ADDRESS_LOADER_CODE
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov bp, BASE_ADDRESS_LOADER_CODE
    mov sp, bp

    mov ax, BASE_ADDRESS_LOADER_DATA >> 4
    mov fs, ax

    call print_init_16

    mov eax, 16161616
    call print_int_16
    mov esi, test_str_16
    call print_str_16
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
    jmp dword SELECTOR_LOADER_CODE: protected_mode_start

    [bits 32]
protected_mode_start:
    mov ax, SELECTOR_LOADER_ROM
    mov ds, ax
    mov es, ax

    mov ax, SELECTOR_LOADER_DATA
    mov fs, ax
    
    mov ax, SELECTOR_STACK
    mov ss, ax
    mov esp, STACK_TOP_INIT_OFFSET

    mov ax, SELECTOR_VIDEO
    mov gs, ax


    mov eax, 32323232
    call print_int_32
    mov esi, test_str_32
    call print_str_32


    jmp $


    test_str_16 db "This is the test message for print_xx_16", CR, LF, 0
    test_str_32 db "This is the test message for print_xx_32", CR, LF, 0




; ==============================================================================
;  Basic Print Procedures
; ------------------------------------------------------------------------------
;  Here are some quite simple print procedures for the loader to use.
;  As soon as we enter the kernel, the kernel will use its own print functions.
;  There are 2 sets of procedures:
;   - print_xxx_16 should be used in the real mode
;   - print_xxx_32 should be used in the protected mode
; ==============================================================================
PRINT_DEFAULT_COLOR equ 0x07     ;white
CURSOR_POS_ADDR     equ 0        ;[fs:0] store cursor position

[bits 16]
; ----------------------------------------------------------
;  Proc Name: print_init_16
;  Function : Initialize GS register and clear the screen
;  Input    : void
;  Output   : void
; ----------------------------------------------------------
print_init_16:
    mov ax, BASE_ADDRESS_VIDEO_MEMORY >> 4
    mov gs, ax
    mov word [fs:CURSOR_POS_ADDR], 0

    xor ebx, ebx
.loop:
    mov dword [gs:ebx], 0
    add ebx, 4
    cmp ebx, 0x8000
    jb .loop
    ret

; ----------------------------------------------------------
;  Proc Name: print_char_16
;  Function : Print a char to the screen. Update ebx reg
;             For non-printing characters, only CR and LF
;             are handled
;  Input    : AL  - the character to be printed
;             EBX - the cursor position
;  Output   : EBX - The updated cursor position
; ----------------------------------------------------------
print_char_16:
    cmp al, CR
    je .is_cr
    cmp al, LF
    je .is_lf
    mov byte [gs:ebx], al
    inc ebx
    mov byte [gs:ebx], PRINT_DEFAULT_COLOR
    inc ebx
    ret
.is_cr:
    mov edx, 0
    mov ecx, 160
    mov eax, ebx
    div cx
    sub bx, dx
    ret
.is_lf:
    add bx, 160
    ret


; ----------------------------------------------------------
;  Proc Name: print_str_16
;  Function : Print a C-style string (end with \0).
;  Input    : ESI - the address of the string
;  Output   : void
; ----------------------------------------------------------
print_str_16:
    mov bx, [fs:CURSOR_POS_ADDR]
.loop:
    lodsb
    cmp al, 0
    jz .end
    call print_char_16
    jmp .loop
.end:
    mov word [fs:CURSOR_POS_ADDR], bx
    ret

; ----------------------------------------------------------
;  Proc Name: print_int_16
;  Function : Print an integer.
;  Input    : EAX - the integer to be printed
;  Output   : void
; ----------------------------------------------------------
print_int_16:
    mov ecx, 10
    mov edx, 0
.transform:
    push dx
    mov edx, 0
    cmp eax, 0
    jz .end_transform
    div ecx
    add dx, '0'
    jmp .transform
.end_transform:
    mov bx, [fs:CURSOR_POS_ADDR]
.loop:
    pop ax
    cmp ax, 0
    jz .endloop
    call print_char_16
    jmp .loop
.endloop:
    mov word [fs:CURSOR_POS_ADDR], bx
    ret


[bits 32]
; ----------------------------------------------------------
;  Proc Name: print_char_32
;  Function : The same as print_char_16
; ----------------------------------------------------------
print_char_32:
    cmp al, CR
    je .is_cr
    cmp al, LF
    je .is_lf
    mov byte [gs:ebx], al
    inc ebx
    mov byte [gs:ebx], PRINT_DEFAULT_COLOR
    inc ebx
    ret
.is_cr:
    mov edx, 0
    mov ecx, 160
    mov eax, ebx
    div ecx
    sub ebx, edx
    ret
.is_lf:
    add ebx, 160
    ret

; ----------------------------------------------------------
;  Proc Name: print_str_32
;  Function : The same as print_str_16
; ----------------------------------------------------------
print_str_32:
    mov bx, [fs:CURSOR_POS_ADDR]
.loop:
    lodsb
    cmp al, 0
    jz .end
    call print_char_32
    jmp .loop
.end:
    mov word [fs:CURSOR_POS_ADDR], bx
    ret

; ----------------------------------------------------------
;  Proc Name: print_int_32
;  Function : The same as print_int_16
; ----------------------------------------------------------
print_int_32:
    mov ecx, 10
    mov edx, 0
.transform:
    push edx
    mov edx, 0
    cmp eax, 0
    jz .end_transform
    div ecx
    add dx, '0'
    jmp .transform
.end_transform:
    mov bx, [fs:CURSOR_POS_ADDR]
.loop:
    pop eax
    cmp eax, 0
    jz .endloop
    call print_char_32
    jmp .loop
.endloop:
    mov word [fs:CURSOR_POS_ADDR], bx
    ret


