;==================================================
;               The loader program
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

; Ram variables
VAR_W_CURSOR_ADDR     equ 0        ; [fs:0] store cursor position
ARD_BASE_ADDRESS      equ 0x1010   ; [0:ARD_BASE_ADDRESS] address of the first Address Range Descriptor
ARD_UNIT_SIZE         equ 32       ; The size of each address range descriptor

SECTION LOADER vstart=BASE_ADDRESS_LOADER_CODE
    mov bp, BASE_ADDRESS_LOADER_CODE
    mov sp, bp

    mov ax, BASE_ADDRESS_LOADER_DATA >> 4
    mov fs, ax

    ; Disable the cursor (BIOS interrupt INT 10H / AH=01H: Set Cursor Type)
    mov ah, 01h
    mov ch, 0010_0000b  ; setting bit5 to 1: no cursor
    int 10h

    call init_print_16

    mov esi, msg_enter_loader
    call print_str_16

    ;----------------------------
    ;    Detect Memory Size
    ; ----------------------------
    ; use BIOS INT 15h, AX=E820h - Query System Address Map
    ; For details, please visit http://www.uruk.org/orig-grub/mem64mb.html
    mov esi, msg_dectect_mem
    call print_str_16

    xor ebx, ebx
    mov di, ARD_BASE_ADDRESS
    mov ecx, ARD_UNIT_SIZE
call_int_e820h:
    mov eax, 0xE820
    mov edx, 0x0534D4150    ;'SMAP'
    int 15h
    jc error_halt
    add di, ARD_UNIT_SIZE
    cmp ebx, 0
    jnz call_int_e820h
calculate_memory:
    xor eax, eax
.loop:
    mov ebx, dword [di]
    add ebx, dword [di + 8]
    cmp ebx, eax
    jb .eax_updated
    mov eax, ebx
.eax_updated:
    cmp di, ARD_BASE_ADDRESS
    jb .end_calculate
    sub di, ARD_UNIT_SIZE
    jmp .loop
.end_calculate:
    push eax
    call print_int_16
    mov esi, str_mem_byte
    call print_str_16
    pop eax
    shr eax, 20
    call print_int_16
    mov esi, str_mem_megabyte
    call print_str_16
    mov esi, str_mem_total
    call print_str_16

    ;----------------------------
    ;    Load GDT Table
    ;----------------------------
load_gdt:
    ; BIOS interrupt INT 13H / AH=02H: Read Desired Sectors Into Memory
    mov ah, 02h
    mov al, HD_SECTOR_CNT_GDT
    mov bx, BASE_ADDRESS_GDT
    mov cx, 0
    mov cl, HD_SECTOR_GDT
    mov dx, 0
    mov dl, 0x80
    int 13h

    mov esi, msg_gdt_loaded
    call print_str_16

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
    mov ebp, esp

    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov esi, msg_protect_mode_on
    call print_str_32

    mov esi, msg_halt
    call print_str_32

    jmp $

error_halt:
    mov esi, msg_halt
    call print_str_32
    jmp $


    msg_enter_loader      db "Loader start!", CR, LF, 0
    msg_dectect_mem       db "Detecting memory... ", 0
    msg_gdt_loaded        db "Loading the global description table...", CR, LF, 0
    msg_protect_mode_on   db "Protected mode activated!", CR, LF, 0
    msg_halt              db CR, LF, "That's all for now. The system is halted.", CR, LF, 0
    msg_error_halt        db "Error encountered! System halted!!", CR, LF, 0

    str_mem_total         db " in total.", CR, LF, 0
    str_mem_byte          db " bytes (", 0
    str_mem_megabyte      db " MiB)", 0
    str_new_line          db  CR, LF, 0



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
VIDEO_MEM_PER_LINE  equ 160      ; 80 char/line * 2 byte/char

[bits 16]
; ----------------------------------------------------------
;  Proc Name: init_print_16
;  Function : Initialize GS register and clear the screen
;  Input    : void
;  Output   : void
; ----------------------------------------------------------
init_print_16:
    mov ax, BASE_ADDRESS_VIDEO_MEMORY >> 4
    mov gs, ax
    mov word [fs:VAR_W_CURSOR_ADDR], 0

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
    mov ecx, VIDEO_MEM_PER_LINE
    mov eax, ebx
    div cx
    sub bx, dx
    ret
.is_lf:
    add bx, VIDEO_MEM_PER_LINE
    ret


; ----------------------------------------------------------
;  Proc Name: print_str_16
;  Function : Print a C-style string (end with \0).
;  Input    : ESI - the address of the string
;  Output   : void
; ----------------------------------------------------------
print_str_16:
    mov bx, [fs:VAR_W_CURSOR_ADDR]
.loop:
    lodsb
    cmp al, 0
    jz .end
    call print_char_16
    jmp .loop
.end:
    mov word [fs:VAR_W_CURSOR_ADDR], bx
    ret

; ----------------------------------------------------------
;  Proc Name: print_int_16
;  Function : Print an integer.
;  Input    : EAX - the integer to be printed
;  Output   : void
; ----------------------------------------------------------
print_int_16:
    cmp eax, 0
    jz .is_zero
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
    mov bx, [fs:VAR_W_CURSOR_ADDR]
.loop:
    pop ax
    cmp ax, 0
    jz .endloop
    call print_char_16
    jmp .loop
.endloop:
    mov word [fs:VAR_W_CURSOR_ADDR], bx
    ret
.is_zero:
    push 0
    push '0'
    jmp .end_transform


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
    mov ecx, VIDEO_MEM_PER_LINE
    mov eax, ebx
    div ecx
    sub ebx, edx
    ret
.is_lf:
    add ebx, VIDEO_MEM_PER_LINE
    ret

; ----------------------------------------------------------
;  Proc Name: print_str_32
;  Function : The same as print_str_16
; ----------------------------------------------------------
print_str_32:
    mov bx, [fs:VAR_W_CURSOR_ADDR]
.loop:
    lodsb
    cmp al, 0
    jz .end
    call print_char_32
    jmp .loop
.end:
    mov word [fs:VAR_W_CURSOR_ADDR], bx
    ret

; ----------------------------------------------------------
;  Proc Name: print_int_32
;  Function : The same as print_int_16
; ----------------------------------------------------------
print_int_32:
    cmp eax, 0
    jz .is_zero
    mov ecx, 10
    mov edx, 0
.transform:
    push edx
    mov edx, 0
    cmp eax, 0
    jz .end_transform
    div ecx
    add edx, '0'
    jmp .transform
.end_transform:
    mov bx, [fs:VAR_W_CURSOR_ADDR]
.loop:
    pop eax
    cmp eax, 0
    jz .endloop
    call print_char_32
    jmp .loop
.endloop:
    mov word [fs:VAR_W_CURSOR_ADDR], bx
    ret
.is_zero:
    push 0
    push '0'
    jmp .end_transform
