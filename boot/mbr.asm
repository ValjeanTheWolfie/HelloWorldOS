;==================================================
;  The loader program for the Master Boot Record
;--------------------------------------------------
; 2020.3.28  ValjeanTheWolfie  Create
;==================================================
%include "./commondefs.asm"

SECTION LOADER vstart=0x7c00
    ;Initialize the segment registers using the values in CS
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ;Initialize the stack pointer register
    mov sp, 0x7c00


    ;-------------------------------------------
    ;  BIOS interrupt: INT 10H / AH=03H
    ;-------------------------------------------
    ; Function ：Read cursor info in the text mode
    ; Note: [i] - input parameters; [o] - output parameters
    ;-------------------------------------------
    ;         AH/BH/CH/DH               AL/BL/CL/DL
    ; AX    [i] 03H                          -
    ; BX    [i] page No.                     -
    ; CX    [o] begin bitmap line     [o] end bitmap line     (cursor shape)
    ; DX    [o] Y coordinate          [o] X coordinate        (cursor position)
    mov ah, 03h
    mov bh, 00h
    int 10h

    ;Call the BIOS interrupt to display the booting message on the screen
    ;-------------------------------------------
    ;  BIOS interrupt: INT 10H / AH=13H
    ;-------------------------------------------
    ; Function ：Print strings in the Teletype Mode
    ;-------------------------------------------
    ;         AH/BH/CH/DH               AL/BL/CL/DL
    ; AX    [i] 13H                [i] output mode (0 - 3)
    ; BX    [i] Page No.           [i] character properties(if AL = 0 or 1)
    ; CX                 [i] string length
    ; DX    [i] Y coordinate       [i] X coordinate           (cursor position)
    ; ES:BP              [i] string address

    ;The parameters for BH, DH and DL have already obtained by INT 10H/AH=03H.
    mov bl, 0x0f ;BL: Character properties
                 ;(MSB)  7   6   5   4   3   2   1   0   (LSB)
                 ;       |   R   G   B   |   R   G   B
                 ;       v   Background  v   Forecolor
                 ;Blinking(1/0 - Y/N)  Brightness(0 - low, 1 - high)
    mov cx, boot_message_len
    ;BP cannot be assigned by an immediate number, so use AX for assistance
    mov ax, boot_message
    mov bp, ax
    ;Then set values for AX
    mov ah, 13H
    mov al, 01b ;bit0: If set 1, move the cursor when finishing printing the string
                ;bit1: Each character in the string contain its property if set 1, 
                ;      otherwise use the one set in BL.
                ;bit2-bit7: not used
    int 10h

    jmp $


    boot_message db CR, LF, "Loading the boot program. Please wait...", CR, LF, 0
    boot_message_len equ ($ - boot_message - 1)


    times 510 - ($ - $$) db 0
    dw 0xaa55