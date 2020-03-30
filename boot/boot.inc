;==================================================
;      Definitions the Master Boot Record
;--------------------------------------------------
; 2020.3.30  ValjeanTheWolfie  Create
;==================================================
%ifndef _BOOT_INC_
%define _BOOT_INC_

%include "commondefs.inc"

LOADER_START_SECTOR  equ 2
LOADER_SECTOR_COUNT  equ 5
LOADER_BASE_ADDRESS  equ 0x8000


%endif ;ifndef _BOOT_INC_

