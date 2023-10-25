;------------------------------------------------------------------------------
; @file:        loader.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/25/2023 09:45 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This program is responsible for the next steps after the boot
;               sector program.
;
;               It performs the following steps:
;
;                   1. Checks if the processor supports long mode (64-bit mode)
;                      and 1GB Page support.
;
;                   2. Prints a success message on the console.
;
;                   3. Halts the processor in an infinite loop.
;
; Revision History:
;
; Revision 0.1: 10/24/2023 Marko Trickovic
; Initial creation of the loader assembly program.
; Added functionality to print a success message on the console.
; Implemented an infinite loop at the end of the program to keep the system
; in a stable state after the loading process is complete.
;
; Revision 0.2  10/25/2023  Marko Trickovic
; Added checks for Long Mode and 1G Page support in the CPUID instruction.
; The code now stores the drive ID in memory.
; The CPUID instruction is executed with EAX=0x80000000 to return the highest
; function number and vendor string.
; The value in EAX is compared with 0x80000001 to check if it's less. If it
; is, the code jumps to NotSupport.
; The CPUID instruction is executed again with EAX=0x80000001 to return
; processor info and feature bits.
; Bit 29 (Long Mode support) in EDX is tested. If it's not set, the code
; jumps to NotSupport.
; Bit 26 (1G Page support) in EDX is tested. If it's not set, the code jumps
; to NotSupport.
;------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7e00]        ; Set origin to boot sector address

start:
    mov [DriveId],dl    ; Store the drive ID in memory
    mov eax,0x80000000  ; Load the value 0x80000000 into the EAX register
    cpuid               ; Execute the CPUID instruction with EAX=0x80000000
    cmp eax,0x80000001  ; Compare the value in EAX with 0x80000001
    jb NotSupport       ; If EAX is less than 0x80000001

    mov eax,0x80000001  ; Load the value 0x80000001 into the EAX register
    cpuid               ; Execute the CPUID instruction with EAX=0x80000001
    test edx,(1<<29)    ; Test if bit 29 (Long Mode support) in EDX is set
    jz NotSupport       ; If bit 29 is not set, jump to NotSupport
    test edx,(1<<26)    ; Test if bit 26 (1G Page support) in EDX is set
    jz NotSupport       ; If bit 26 is not set, jump to NotSupport

    mov ah,0x13         ; Write String function
    mov al,1            ; String with color
    mov bx,0xa          ; Light green on black
    xor dx,dx           ; Row 0, column 0
    mov bp,Message      ; Message address
    mov cx,MessageLen   ; Length of the string
    int 0x10            ; Call BIOS interrupt 0x10

NotSupport:
End:
    hlt             ; Halt the processor, waiting for the next interrupt
    jmp End         ; Jump back to 'End', creating an infinite loop

DriveId:    db 0                ; Byte for DriveId
Message:    db "long mode is supported"  ; Define a byte array 'Message'
MessageLen: equ $-Message   ; Length of 'Message' by '$' minus start address
