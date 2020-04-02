;==================================================
;      Definitions the Master Boot Record
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%define CR 0x0d
%define LF 0x0a

VIDEO_MEMORY_TEXT_ADDRESS   equ 0xb8000

LOADER_START_SECTOR         equ 2
LOADER_SECTOR_COUNT         equ 5
LOADER_GDT_TABLE_SIZE       equ 256

LOADER_BASE_ADDRESS         equ 0x8000
LOADER_HEAP_ADDRESS         equ 0x10000
LOADER_STACK_ADDRESS        equ 0x30000

; -----------------------------
;   GDT Entry (bit63 - bit32)
; -----------------------------
; (MSB)                                                       (LSB)
; | 63......56 | 55...52 | 51.......48 | 47.......40 | 39......32 |
; | Base 31:24 |  Flags  | Limit 16:19 | Access Byte | Base 23:16 |

; - Access Byte
; (MSB)                       (LSB)
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
GDT_ACCESS_BYTE_CODE   equ 1_00_1_1010b ;Ex = 1, C = 0
GDT_ACCESS_BYTE_ROM    equ 1_00_1_0000b ;Ex = 0, RW = 0
GDT_ACCESS_BYTE_HEAP   equ 1_00_1_0010b ;RW = 1
GDT_ACCESS_BYTE_STACK  equ 1_00_1_0110b ;D = 1

; - GDT Flags
; (MSB)       (LSB)
; | 7 | 6 | 5 | 4 |
; | Gr| Sz| 0 | 0 |
; Gr: Granularity bit. If 0 the limit is in 1 B blocks (byte granularity), if 1 the limit is in 4 KiB blocks (page granularity).
; Sz: Size bit. If 0 the selector defines 16 bit protected mode. If 1 it defines 32 bit protected mode. You can have both 16 bit and 32 bit selectors at once.
GDT_FLAGS_BIYE_16 equ 0000b
GDT_FLAGS_BIYE_32 equ 0100b
GDT_FLAGS_PAGE_16 equ 1000b
GDT_FLAGS_PAGE_32 equ 1100b