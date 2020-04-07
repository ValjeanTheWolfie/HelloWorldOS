;==================================================
;      Definitions the Master Boot Record
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%define CR 0x0d
%define LF 0x0a

; ---------------------------------
;          Disk layout
; ---------------------------------
HD_SECTOR_GDT               equ 2
HD_SECTOR_LOADER            equ 4
HD_SECTOR_KERNEL            equ 8

HD_SECTOR_CNT_GDT           equ HD_SECTOR_LOADER - HD_SECTOR_GDT
HD_SECTOR_CNT_LOADER        equ HD_SECTOR_KERNEL - HD_SECTOR_LOADER
HD_SECTOR_CNT_KERNEL        equ 64


; ---------------------------------
;         Memory layout
; ---------------------------------
BASE_ADDRESS_UNLIMITED      equ 0
BASE_ADDRESS_GDT            equ 0x800
BASE_ADDRESS_LOADER_CODE    equ 0x8000
BASE_ADDRESS_LOADER_DATA    equ 0x1000
BASE_ADDRESS_STACK          equ 0x70000
BASE_ADDRESS_VIDEO_MEMORY   equ 0xb8000

LIMIT_UNLIMITED             equ 0xFFFFF
LIMIT_LOADER_DATA           equ 6       ;28 KiB
LIMIT_STACK                 equ 23      ;96 Kib
LIMIT_VIDEO                 equ 7       ;32 KiB

SELECTOR_GDT                equ (1 << 3)
SELECTOR_VIDEO              equ (2 << 3)
SELECTOR_STACK              equ (3 << 3)
SELECTOR_LOADER_CODE        equ (4 << 3)
SELECTOR_LOADER_DATA        equ (5 << 3)
SELECTOR_LOADER_ROM         equ (6 << 3)

GDT_TABLE_SIZE              equ 512  ; 512 Bytes, i.e. 64 entries
GDT_REGISTER_ADDR           equ BASE_ADDRESS_GDT + GDT_TABLE_SIZE

STACK_TOP_INIT_OFFSET       equ 0x10000