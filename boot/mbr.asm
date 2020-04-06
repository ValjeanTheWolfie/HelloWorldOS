;==================================================
;            The Master Boot Record
;--------------------------------------------------
; 2020.3.28  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"

SECTION MBR vstart=0x7c00
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
    ; Function ：Read Cursor Position
    ; Note: [i] - input parameters; [o] - returned parameters
    ;-------------------------------------------
    ;         AH/BH/CH/DH               AL/BL/CL/DL
    ; AX    [i] 03H                          -
    ; BX    [i] page No.                     -
    ; CX    [o] top bitmap line       [o] bottom bitmap line  (cursor shape)
    ; DX    [o] Y coordinate          [o] X coordinate        (cursor position)
    mov ah, 03h
    mov bh, 00h
    int 10h

    ;Call BIOS interrupt to display the booting message on the screen
    ;-------------------------------------------
    ;  BIOS interrupt: INT 10H / AH=13H
    ;-------------------------------------------
    ; Function ：Write String
    ;-------------------------------------------
    ;         AH/BH/CH/DH               AL/BL/CL/DL
    ; AX    [i] 13H                [i] output mode (0 - 3)
    ; BX    [i] Page No.           [i] character properties(if AL = 0 or 1)
    ; CX                 [i] string length
    ; DX    [i] Y coordinate       [i] X coordinate           (cursor position)
    ; ES:BP              [i] string address
    ; - Character properties (for BL)
    ;     (MSB)  7   6   5   4   3   2   1   0   (LSB)
    ;            |   R   G   B   |   R   G   B
    ;            v   Background  v   Forecolor
    ;     Blinking(1/0 - Y/N)  Brightness(0 - low, 1 - high)
    ; - Output mode (for AL)
    ;       bit0: If set 1, move the cursor when finishing printing the string
    ;       bit1: Each character in the string contain its property if set 1, 
    ;             otherwise use the one set in BL.
    ;       bit2-bit7: not used

    ;The parameters for BH, DH and DL have already obtained by INT 10H/AH=03H.
    mov bl, 0x0f 
    mov cx, start_message_len
    ;BP cannot be assigned by an immediate number, so use AX for assistance
    mov ax, start_message
    mov bp, ax
    ;Then set values for AX
    mov ah, 13H
    mov al, 01b 
    int 10h

    ;Call BIOS interrupt to load loader from the hard disk
    ;-------------------------------------------
    ;  BIOS interrupt: INT 13H / AH=02H
    ;-------------------------------------------
    ; Function ：Read Desired Sectors Into Memory
    ;-------------------------------------------
    ;         AH/BH/CH/DH               AL/BL/CL/DL
    ; AX    [i] 02H                [i] number of sectors
    ; ES:BX             [i] Address of buffer
    ; CX    [i] track number       [i] sector number
    ; DX    [i] head number        [i] drive number
    ;
    ; - On Return:
    ;   CF = 1 - Status is non 0
    ;      = 0 - Status is 0
    ;   AL: Number of sectors actually transferred
    ;   AH: Status of operation 

    mov si, 5 ;The maximum attempts to read the disk
read_loader:
    mov ah, 02h
    mov al, HD_SECTOR_CNT_LOADER
    mov bx, BASE_ADDRESS_LOADER_CODE
    mov cx, 0
    mov cl, HD_SECTOR_LOADER
    mov dx, 0
    mov dl, 0x80
    int 13h
    jc read_fail
    jmp BASE_ADDRESS_LOADER_CODE
read_fail:
    dec si
    cmp si, 0
    jnz read_loader
    ;After 5 attempts, print the reading failure message and halt the system
    mov ah, 03h
    mov bh, 00h
    int 10h
    mov bl, 0x0f
    mov cx, read_fail_messagelen
    mov ax, read_fail_message
    mov bp, ax
    mov ah, 13H
    mov al, 01b 
    int 10h
    jmp $

; ==================
;    Data part
; ==================
    start_message db CR, LF, "Starting TinySYS...", CR, LF, 0
    start_message_len equ ($ - start_message - 1)

    read_fail_message db "Failed to read the hard disk. Please examine the hardware setting and restart the system.", CR, LF, 0
    read_fail_messagelen equ ($ - read_fail_message - 1)

; ========================
;   Disk Partition Table
; ========================
    times 510 - ($ - $$)db 0 ;Padding data
    dw 0xaa55                ;Bootable mark