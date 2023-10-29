;------------------------------------------------------------------------------
; @file:        loader.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/29/2023 04:20 PM
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
;                   2. LoadKernel subroutine:
;
;                       - Sets up the necessary parameters for a BIOS disk read
;                         operation in extended mode.
;
;                       - Triggers the operation via interrupt 0x13.
;
;                       - Handles potential read errors.
;
;                       - The parameters for the disk read operation are stored
;                         in a data structure pointed to by the Source Index
;                         (si) register.
;
;                   3. Memory map retrieval:
;
;                       - GetMemInfoStart function gets the initial memory map
;                         by triggering a BIOS interrupt.
;
;                       - GetMemInfo function retrieves subsequent memory map
;                         entries.
;
;                       - GetMemDone function writes a string to the console
;                         indicating the completion of memory map retrieval.
;
;                   4. Implement TestA20 function. This function is testing if
;                      the A20 line is enabled. The A20 line is a hardware line
;                      that controls whether addresses above 1MB are wrapped
;                      around to zero or not. This function writes different
;                      values to two addresses that differ only in the 21st
;                      bit and checks if they are seen as different or the
;                      same. If they are seen as different, then A20 line is
;                      enabled. If they are seen as the same, then A20 line is
;                      disabled.
;
;                   5. Prints a success message on the console.
;
;                   6. Halts the processor in an infinite loop.
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
;
; Revision 0.4: 10/27/2023  Marko Trickovic
; Added functions for getting system memory map (GetMemInfoStart, GetMemInfo,
; and GetMemDone).
;
; Revision 0.5  10/29/2023  Marko Trickovic
; Added functions for testing if the A20 line is enabled (TestA20,
; SetA20LineDone).
;------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7e00]        ; Set origin to boot sector address

; This code is used to check if the CPU supports long mode and 1G page support.
; Long mode is a feature of the x86-64 architecture that allows 64-bit code to
; be executed natively on the CPU. 1G page support is a feature that allows the
; use of larger page sizes, which can improve performance in certain situations.
;
; The code starts by storing the drive ID in memory using mov [DriveId],dl.
; It then executes the CPUID instruction with EAX set to 0x80000000 to
; determine if the CPU supports extended features. If EAX is less than
; 0x80000001, it means that the CPU does not support extended features,
; and the code jumps to NotSupport.
;
; If the CPU does support extended features, the code executes the CPUID
; instruction again with EAX set to 0x80000001. It then tests bit 29
; (Long Mode support) and bit 26 (1G Page support) of the EDX register
; using the test instruction. If either of these bits is not set, it means that
; the CPU does not support long mode or 1G page support, and the code jumps to
; NotSupport.
;
; The purpose of this code is to check if the CPU supports long mode and 1G
; page support before attempting to use these features. This can help avoid
; errors or crashes when running code that requires these features.
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
;
; The purpose of this code is to load the kernel from the hard disk partition.
; The function LoadKernel uses BIOS interrupt 0x13 and function 0x42 to read
; data from the hard disk. The ReadPacket structure is used to specify the
; location and size of the data to be read. Specifically, the size of the
; ReadPacket structure is set to 16 bytes, and the number of sectors to read
; is set to 100. The memory address where the data will be read is set to 0,
; and the segment offset is set to 0x1000.
;
; The kernel is written starting from the 6th sector, which is specified by
; setting dword[si+8] to 6. The high address for reading from the hard disk
; partition is set to 0, and the drive number from which to read is set
; using dl. Finally, BIOS interrupt 0x13 is called using int 0x13, and if
; there is an error, the code jumps to ReadError.
;
; This function loads the kernel from the hard disk partition using BIOS
; interrupt 0x13 and function 0x42.
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

; Function: GetMemInfoStart
;
; This code is using BIOS interrupt 0x15 to read memory information about
; the PC system it's run on. Specifically, it uses the 0xe820 function to
; get the system memory map. The EDX register is set to the signature SMAP,
; and ECX is set to 20, which is the size of the memory range descriptor.
; The buffer to store memory range descriptors is set to 0x9000. The
; enumeration starts with EBX being set to zero. The code then call BIOS
; interrupt 0x15 and jumpts to NotSupport if there is an error.
;
; If there are no errors, the code checks if all memory range descriptors have
; been obtained. If not, it gets the next descriptor by incrementing the buffer
; pointer by 20 bytes and calling BIOS interrupt 0x15 again.
;
; When all descriptors have been obtained, the code jumps to GetMemDone.
; This function writes a string with color to the screen using BIOS interrupt
; 0x10. The string is stored at Message, and its length is stored in MessageLen.
; The color of the string is light green on black.
;
; This code is used to get information about the memory layout of a PC system.
GetMemInfoStart:
    mov eax,0xe820          ; Function for Getting System Memory Map
    mov edx,0x534d4150      ; This is 'SMAP' signature
    mov ecx,20              ; Size of the memory range descriptor
    mov edi,0x9000          ; Buffer to store memory range descriptors
    xor ebx,ebx             ; Indicate start of enumeration
    int 0x15                ; Call BIOS interrupt 0x15
    jc NotSupport           ; Jump if error

    test ebx,ebx            ; All memory range descriptors have been obtained
    jnz GetMemInfo          ; Get next descriptor

; Function: GetMemInfo
GetMemInfo:
    add edi,20              ; Point to next descriptor in buffer
    mov eax,0xe820          ; Function for Getting System Memory Map
    mov edx,0x534d4150      ; This is 'SMAP' signature
    mov ecx,20              ; Size of the memory range descriptor
    int 0x15                ; Call BIOS interrupt 0x15
    jc GetMemDone           ; Jump if error

; Function: GetMemDone:
GetMemDone:
    mov ah,0x13         ; Write String function
    mov al,1            ; String with color
    mov bx,0xa          ; Light green on black
    xor dx,dx           ; Row 0, column 0
    mov bp,Message      ; Message address
    mov cx,MessageLen   ; Length of the string
    int 0x10            ; Call BIOS interrupt 0x10

; Function: TestA20
;
; This function checks if A20 line is enabled by default. It does so by writing
; some value (in this case) 0xA200 in 0000:7c00, and tries to read from the
; location FFFF:7c10. If the A20 line is disabled, this will wrap around and
; read from location 0x7c00 instead. If the values at 0000:7c00 and FFFF:7c10
; are not equal, it means that the A20 line is enabled. This is because when
; the A20 line is enabled, addresses above 1MB can be accessed directly without
; wrapping around to lower memory locations. So, if the values are not equal,
; it indicates that the write to 0000:7c00 did not affect the value at
; FFFF:7c10, which means the A20 line is enabled. If they are equal, it means
; that the write to 0000:7c00 did affect the value at FFFF:7c10 due to address
; line wrapping, which means the A20 line is disabled.
;
; Checking for the A20 line is important because it controls how memory
; addresses are interpreted. By checking if the A20 line is enabled or
; disabled, this code can ensure that memory above 1MB can be accessed
; directly without any issues.
TestA20:
    mov ax,0xffff               ; Set maximum value in AX
    mov es,ax                   ; Set ES to point to the top of memory
    mov word[ds:0x7c00],0xa200  ; Move the value 0xa200 into memory location
    cmp word[es:0x7c10],0xa200  ; Check if we can read above 1mb address space
    jne SetA20LineDone          ; If the values are not equal, jump to Done
    mov word[0x7c00],0xb200     ; Set memory location 0x7c00 with 0xb200
    cmp word[es:0x7c10],0xb200  ; Compare memory location 0x7c10 with 0xb200
    je End                      ; If the values are equal, jump to End

; Function: SetA20LineDone
SetA20LineDone:
   xor ax,ax                    ; Zero out AX
   mov es,ax                    ; Set extra segment to 0
   mov ah,0x13                  ; Function for Writing String
   mov al,1                     ; String with color
   mov bx,0xa                   ; Light green on black
   xor dx,dx                    ; Row 0, column 0
   mov bp,Message               ; Message address
   mov cx,MessageLen            ; Length of the string
   int 0x10                     ; Call BIOS interrupt 0x10

ReadError:
NotSupport:
End:
    hlt             ; Halt the processor, waiting for the next interrupt
    jmp End         ; Jump back to 'End', creating an infinite loop

DriveId:    db 0                        ; Byte for DriveId
Message:    db "a20 line is on"         ; Define a byte array 'Message'
MessageLen: equ $-Message   ; Length of 'Message' by '$' minus start address
ReadPacket: times 16 db 0   ; Allocate 16B, for storing a packet from the disk
