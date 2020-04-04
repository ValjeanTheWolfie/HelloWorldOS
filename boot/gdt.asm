;==================================================
;          Pre-defined GDT Table
;--------------------------------------------------
; 2020.4.2  ValjeanTheWolfie  Create
;==================================================
%include "boot.inc"
; | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
; | Pr| Privl | S | Ex|D/C| RW| Ac|
GDT_ACCESS_BYTE_CODE equ 1_00_1_1010b ;Ex = 1
GDT_ACCESS_BYTE_ROM  equ 1_00_1_0000b ;Ex = 0, RW = 0
GDT_ACCESS_BYTE_DATA equ 1_00_1_0010b ;Ex = 0, RW = 1
; | 7 | 6 | 5 | 4 |
; | Gr| Sz| 0 | 0 |
GDT_FLAGS_1B_16 equ 0000b
GDT_FLAGS_1B_32 equ 0100b
GDT_FLAGS_4K_16 equ 1000b
GDT_FLAGS_4K_32 equ 1100b

%define GDT_ENTRY(baseAddr, limit, accessByte, flag)                        \
    dw limit,                                                               \
       baseAddr & 0xFFFF,                                                   \
       (accessByte << 8) | ((baseAddr >> 16) & 0xFF),                       \
       ((baseAddr >> 24) & 0xFF00) | (flag << 4) | ((limit >> 16) & 0xF)

SECTION LOADER vstart=BASE_ADDRESS_GDT
    ; 0 - The 1st GDT entry is inaccessible
    GDT_ENTRY(0, 0, 0, 0) 
    ; 1 - The GDT table segment
    GDT_ENTRY(BASE_ADDRESS_GDT, (GDT_TABLE_SIZE - 1), GDT_ACCESS_BYTE_DATA, GDT_FLAGS_1B_32)
    ; 2 - The video memory segment
    GDT_ENTRY(BASE_ADDRESS_VIDEO_MEMORY, LIMIT_VIDEO, GDT_ACCESS_BYTE_DATA, GDT_FLAGS_4K_32)
    ; 3 - The stack segment
    GDT_ENTRY(BASE_ADDRESS_STACK, LIMIT_STACK, GDT_ACCESS_BYTE_DATA, GDT_FLAGS_4K_32)
    ; 4 - The loader code segment
    GDT_ENTRY(BASE_ADDRESS_UNLIMITED, LIMIT_UNLIMITED, GDT_ACCESS_BYTE_CODE, GDT_FLAGS_4K_32)
    ; 5 - The loader data segment
    GDT_ENTRY(BASE_ADDRESS_LOADER_DATA, LIMIT_LOADER_DATA, GDT_ACCESS_BYTE_DATA, GDT_FLAGS_4K_32)
    ; 6 - The loader rom segment
    GDT_ENTRY(BASE_ADDRESS_UNLIMITED, LIMIT_UNLIMITED, GDT_ACCESS_BYTE_ROM, GDT_FLAGS_4K_32)


    ;Padding bits
    times (GDT_TABLE_SIZE - ($ - $$)) db 0

    ;GDT Register
    dw GDT_TABLE_SIZE - 1
    dd BASE_ADDRESS_GDT
    align 8, db 0

; ======================================
;  Appendix: GDT Entry Stucture Info 
;        (From wiki.osdev.org)
; ======================================
; |(MSB)                   - GDT Entry -                     (LSB)|
; | 31..............................16 | 15.....................0 |
; |             Base 15:0              |        Limit 15:0        |
; | 63......56 | 55...52 | 51.......48 | 47.......40 | 39......32 |
; | Base 31:24 |  Flags  | Limit 19:16 | Access Byte | Base 23:16 |
;
; |(MSB)   - Access Byte -   (LSB)|
; | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
; | Pr| Privl | S | Ex|D/C| RW| Ac|
; Pr   : Present bit. This must be 1 for all valid selectors.
; Privl: Privilege, 2 bits. Contains the ring level, 0 = highest (kernel), 3 = lowest (user applications).
; S    : Descriptor type. This bit should be set for code or data segments and should be cleared for system segments (eg. a Task State Segment)
; Ex   : Executable bit. If 1 code in this segment can be executed, ie. a code selector. If 0 it is a data selector.
; DC   : Direction bit/Conforming bit.
;          Direction bit for data selectors: Tells the direction. 0 the segment grows up. 1 the segment grows down, ie. the offset has to be greater than the limit.
;          Conforming bit for code selectors:  If 1 code in this segment can be executed from an equal or lower privilege level. For example, code in ring 3 can far-jump to conforming code in a ring 2 segment. The privl-bits represent the highest privilege level that is allowed to execute the segment. For example, code in ring 0 cannot far-jump to a conforming code segment with privl==0x2, while code in ring 2 and 3 can. Note that the privilege level remains the same, ie. a far-jump form ring 3 to a privl==2-segment remains in ring 3 after the jump.
;                                              If 0 code in this segment can only be executed from the ring set in privl.
; RW   : Readable bit/Writable bit.  Readable bit for code selectors: Whether read access for this segment is allowed. Write access is never allowed for code segments.
;                                    Writable bit for data selectors: Whether write access for this segment is allowed. Read access is always allowed for data segments.
; Ac   : Accessed bit. Just set to 0. The CPU sets this to 1 when the segment is accessed.
;
; | - GDT Flags - |
; (MSB)       (LSB)
; | 7 | 6 | 5 | 4 |
; | Gr| Sz| 0 | 0 |
; Gr: Granularity bit. If 0 the limit is in 1 B blocks (byte granularity), if 1 the limit is in 4 KiB blocks (page granularity).
; Sz: Size bit. If 0 the selector defines 16 bit protected mode. If 1 it defines 32 bit protected mode. You can have both 16 bit and 32 bit selectors at once.
; The rest 2 bits is for x64. Just set 0 for our x86 system.