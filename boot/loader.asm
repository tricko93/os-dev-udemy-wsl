;------------------------------------------------------------------------------
; @file:        loader.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/26/2023 09:10 PM
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
;                   2. LoadKernel subroutine, which sets up the necessary
;                      parameters for a BIOS disk read operatin in extended
;                      mode, triggers the operatin via interrupt 0x13, and
;                      handles potential read errors. The parameters for the
;                      disk read operation are stored in a data structure
;                      pointed to by the Source Index (si) register.
;
;                   3. Prints a success message on the console.
;
;                   4. Halts the processor in an infinite loop.
;
; Usage: make
;
; Revision History:
;
; Revision 0.1: 10/24/2023 Marko Trickovic
; Initial creation of the loader assembly program.
; Added functionality to print a success message on the console.
; Implemented an infinite loop at the end of the program to keep the system
; in a stable state after the loading process is complete.
;
; Revision 0.2: 10/25/2023  Marko Trickovic
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
;
; Revision 03: 10/26/2023  Marko Trickovic
; Initial version with LoadKernel function implementation.
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

; Function: LoadKernel
LoadKernel:
    mov si,ReadPacket       ; Set SI to the address of ReadPacket
    mov word[si],0x10       ; Set the size of the ReadPacket structure to 16B
    mov word[si+2],100      ; Set the number of sectors to read to 100
    mov word[si+4],0        ; Set the memory address where to read data
    mov word[si+6],0x1000   ; Set the segment offset to 0x1000
    mov dword[si+8],6       ; We write our kernel from 6th sector
    mov dword[si+0xc],0     ; Address high for reading from hard disk partition
    mov dl,[DriveId]        ; Set the drive number from which to read
    mov ah,0x42             ; Function for Extended Disk Read
    int 0x13                ; Call BIOS interrupt 0x13
    jc ReadError            ; Jump if error

    mov ah,0x13         ; Write String function
    mov al,1            ; String with color
    mov bx,0xa          ; Light green on black
    xor dx,dx           ; Row 0, column 0
    mov bp,Message      ; Message address
    mov cx,MessageLen   ; Length of the string
    int 0x10            ; Call BIOS interrupt 0x10

ReadError:
NotSupport:
End:
    hlt             ; Halt the processor, waiting for the next interrupt
    jmp End         ; Jump back to 'End', creating an infinite loop

DriveId:    db 0                    ; Byte for DriveId
Message:    db "kernel is loaded"   ; Define a byte array 'Message'
MessageLen: equ $-Message   ; Length of 'Message' by '$' minus start address
ReadPacket: times 16 db 0   ; Allocate 16B, for storing a packet from the disk
