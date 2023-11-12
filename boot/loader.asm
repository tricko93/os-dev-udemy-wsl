;------------------------------------------------------------------------------
; @file:        loader.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        11/12/2023 10:34 PM
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
;                   4. Implement TestA20 routine. This routine is testing if the
;                      A20 line is enabled by:
;
;                       - Writing different values to two addresses that differ
;                         only in the 21st bit.
;
;                       - Checking if they are seen as different or the same.
;
;                       - If they are different, then A20 line is enabled.
;
;                       - If they are the same, then A20 line is disabled.
;
;                   5. Code to enter protected mode from real mode.
;
;                       - It defines the Global Descriptor Table (GDT) and the
;                         Interrupt Descriptor Table (IDT) for protected mode.
;
;                       - It switches to protected mode by setting the PE bit in
;                         CR0 register and performs a far jump to a 32-bit code
;                         segment.
;
;                       - It prints a message on the display using the video
;                         memory at segment 0xb800.
;
;                   6. Code to enable paging and enter long mode from protected
;                      mode.
;
;                       - Prepare the machine for paging by setting up the page
;                         directory and page table entries.
;
;                       - Load the global descriptor table (GDT) by using the
;                         lgdt instruction.
;
;                       - Enable paging by setting the paging bit in the control
;                         register 0 (cr0).
;
;                       - Switch to long mode by setting the long mode bit in
;                         the extended feature enable register (EFER) and
;                         jumping to a 64-bit code segment.
;
;                   7. Code to relocate the Kernel from 0x10000 to 0x200000
;                      memory address.
;
;                       - Relocates the Kernel from 0x10000 to 0x200000.
;
;                       - Jumps to the kernel entry point at 0x200000.
;
;                       - Halts the processor in an infinite loop.
;
; Usage: make
;
; Revision History:
;
;   - Revision 0.1: 10/24/2023 Marko Trickovic
;     Initial creation of the loader assembly program.
;     Added functionality to print a success message on the console.
;     Implemented an infinite loop at the end of the program to keep the system
;     in a stable state after the loading process is complete.
;
;   - Revision 0.2: 10/25/2023 Marko Trickovic
;     Added checks for Long Mode and 1G Page support in the CPUID instruction.
;     The code now stores the drive ID in memory.
;     The CPUID instruction is executed with EAX=0x80000000 to return the
;     highest function number and vendor string.
;     The value in EAX is compared with 0x80000001 to check if it's less. If it
;     is, the code jumps to NotSupport.
;     The CPUID instruction is executed again with EAX=0x80000001 to return
;     processor info and feature bits.
;     Bit 29 (Long Mode support) in EDX is tested. If it's not set, the code
;     jumps to NotSupport.
;     Bit 26 (1G Page support) in EDX is tested. If it's not set, the code jumps
;     to NotSupport.
;
;   - Revision 03: 10/26/2023  Marko Trickovic
;     Initial version with LoadKernel function implementation.
;
;   - Revision 0.4: 10/27/2023  Marko Trickovic
;     Added functions for getting system memory map (GetMemInfoStart,
;     GetMemInfo, and GetMemDone).
;
;   - Revision 0.5: 10/29/2023  Marko Trickovic
;     Added functions for testing if the A20 line is enabled (TestA20,
;     SetA20LineDone).
;
;   - Revision 0.6: 10/29/2023  Marko Trickovic
;     Added SetVideoMode and PrintMessage function implementations.
;
;   - Revision 0.7: 10/29/2023  Marko Trickovic
;     Added code to enter protected mode from real mode.
;
;   - Revision 0.8: 10/29/2023  Marko Trickovic
;     Added code to enable paging and enter long mode from protected mode.
;
;   - Revision 0.9  10/30/2023  Marko Trickovic
;     Code to relocate the Kernel from 0x10000 to 0x200000 memory address.
;
;   - Revision 1.0: 11/12/2023 Marko Trickovic
;     Refactored the comments to improve readability.
;------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7e00]        ; Set origin to loader program address

; @routine:         start
; @brief:           Checks if the processor supports long mode and 1G page.
;
; @param:     dl    A register that holds the drive ID from which the program
;                   was loaded.
; @param:     eax   A register that holds the function number for the CPUID
;                   instruction.
;
; @return:          None. If the processor supports long mode and 1G page, the
;                   routine continues to the next step. If not, the routine
;                   jumps to NotSupport label.
;
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

; @routine:   LoadKernel
; @brief:     Loads a kernel from a disk into memory.
;
; @param:     si    A pointer to the ReadPacket structure that contains the
;                   parameters for the disk read operation.
; @param:     dl    The drive number from which to read the kernel.
; @param:     ah    The function number for the Extended Disk Read BIOS
;                   interrupt (0x42).
;
; @return:    None. If the disk read operation is successful, the kernel is
;             loaded into memory at segment 0x1000. If there is an error, the
;             routine jumps to ReadError label.
;
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

; @routine:   GetMemInfoStart
; @brief:     Gets the initial memory map entry from the BIOS.
;
; @param:     eax   The function number for the Getting System Memory Map BIOS
;                   interrupt (0xe820).
; @param:     edx   The signature value to indicate the presence of the memory
;                   map function ('SMAP').
; @param:     ecx   The size of the memory range descriptor structure (20
;                   bytes).
; @param:     edi   A pointer to the buffer where to store the memory range
;                   descriptor.
; @param:     ebx   The continuation value to indicate the start or end of the
;                   enumeration (0 for start, nonzero for end).
;
; @return:    None. If the memory map function is supported and successful, the
;             memory range descriptor is stored in the buffer pointed by edi,
;             and the continuation value is stored in ebx. If there is an error
;             or the function is not supported, the routine jumps to NotSupport
;             label.
;
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

; @routine:   GetMemInfo
; @brief:     Gets the next memory map entry from the BIOS.
;
; @param:     edi   A pointer to the buffer where to store the memory range
;                   descriptor.
; @param:     eax   The function number for the Getting System Memory Map BIOS
;                   interrupt (0xe820).
; @param:     edx   The signature value to indicate the presence of the memory
;                   map function ('SMAP').
; @param:     ecx   The size of the memory range descriptor structure (20
;                   bytes).
;
; @return:    None. If the memory map function is supported and successful, the
;             memory range descriptor is stored in the buffer pointed by edi,
;             and the continuation value is stored in ebx. If there is an error
;             or the end of the enumeration is reached, the routine jumps to
;             GetMemDone label.
;
GetMemInfo:
    add edi,20              ; Point to next descriptor in buffer
    mov eax,0xe820          ; Function for Getting System Memory Map
    mov edx,0x534d4150      ; This is 'SMAP' signature
    mov ecx,20              ; Size of the memory range descriptor
    int 0x15                ; Call BIOS interrupt 0x15
    jc GetMemDone           ; Jump if error

; @label:     GetMemDone
; @brief:     Get the memory map finished.
;
; @return:    None.
;
GetMemDone:

; @routine:   TestA20
; @brief:     Tests if the A20 line is enabled or disabled.
;
; @param:     ax    A register that holds the maximum value (0xffff) to set the
;                   segment register ES.
; @param:     es    A segment register that points to the top of the memory
;                   (0xffff0000).
; @param:     ds    A segment register that points to the base of the memory
;                   (0x00000000).
;
; @return:    None. If the A20 line is enabled, the routine jumps to
;             SetA20LineDone label. If the A20 line is disabled, the routine
;             jumps to End label.
;
TestA20:
    mov ax,0xffff               ; Set maximum value in AX
    mov es,ax                   ; Set ES to point to the top of memory
    mov word[ds:0x7c00],0xa200  ; Move the value 0xa200 into memory location
    cmp word[es:0x7c10],0xa200  ; Check if we can read above 1mb address space
    jne SetA20LineDone          ; If the values are not equal, jump to Done
    mov word[0x7c00],0xb200     ; Set memory location 0x7c00 with 0xb200
    cmp word[es:0x7c10],0xb200  ; Compare memory location 0x7c10 with 0xb200
    je End                      ; If the values are equal, jump to End

; @routine:   SetA20LineDone
; @brief:     Resets the segment registers after testing the A20 line.
;
; @param:     ax    A register that holds the value 0 to clear the segment
;                   register ES.
; @param:     es    A segment register that is set to 0 to point to the base of
;                   the memory.
;
; @return:    None. This routine does not return any value.
;
SetA20LineDone:
    xor ax,ax                    ; Zero out AX
    mov es,ax                    ; Set extra segment to 0

; @routine:   SetVideoMode
; @brief:     Sets the video mode to 80x25 text and switches to protected mode.
;
; @param:     ax    A register that holds the video mode number (3) to pass to
;                   the BIOS interrupt 0x10.
;
; @return:    None. This routine does not return any value. It performs a far
;             jump to the PMEntry label in the code segment 8.
;
SetVideoMode:
    mov ax,3                    ; Video mode number in AX (3 = 80x25 text)
    int 0x10                    ; BIOS interrupt 0x10 to set video mode

    cli                         ; Disable hardware interrupts
    lgdt [Gdt32Ptr]             ; Load GDTR from Gdt32Ptr
    lidt [Idt32Ptr]             ; Load IDTR from Idt32Ptr

    mov eax,cr0                 ; Move CR0 to EAX
    or eax,1                    ; Enable protected mode in EAX
    mov cr0,eax                 ; Move EAX back to CR0

    jmp 8:PMEntry               ; Far jump to code segment 8 and offset PMEntry


; @routine:   ReadError
; @brief:     Handles the error case when the disk read operation fails.
;
; @return:    None. This label does not return any value.
;
ReadError:

; @label:     NotSupport
; @brief:     Handles the error case when the processor does not support long
;             mode or 1G page.
;
; @return:    None. This label does not return any value.
;
NotSupport:

; @label:     End
; @brief:     Halts the CPU and creates an infinite loop.
;
; @return:    None. This label does not return any value.
;
End:
    hlt                         ; Halt the CPU, waiting for the next interrupt
    jmp End                     ; Jump back to 'End', creating an infinite loop

[BITS 32]                       ; Use 32-bit mode

; @routine:   PMEntry
; @param:     ax    A register that holds the data segment selector (0x10) to
;                   set the segment registers.
; @param:     ds    A segment register that points to the data segment.
; @param:     es    A segment register that points to the extra segment.
; @param:     ss    A segment register that points to the extra segment.
; @param:     esp   A register that holds the stack pointer address (0x7c00).
; @param:     edi   A register that holds the page directory base address
;                   (0x70000).
; @param:     eax   A register that holds the value to set the control
;                   registers.
; @param:     ecx   A register that holds the size of the memory range
;                   descriptor structure (20 bytes).
;
; @return:    None. This label sets up the segment registers, clears the page
;             directory, loads the GDT and IDT, enables PAE, sets the PDBR,
;             enables long mode, enables paging, and switches to long mode by
;             jumping to LMEntry label.
;
PMEntry:                        ; Entry point for protected mode

    mov ax,0x10                 ; Move data segment selector (0x10) to AX
    mov ds,ax                   ; Move data segment selector from AX to DS
    mov es,ax                   ; Move data segment selector from AX to ES
    mov ss,ax                   ; Move stack segment selector from AX to SS
    mov esp,0x7c00              ; Move stack pointer address (0x7c00) to ESP

    cld                         ; Increment edi after store
    mov edi,0x70000             ; Page directory base
    xor eax,eax                 ; Clear page directory
    mov ecx,0x10000/4           ; Page directory size
    rep stosd                   ; Store eax to edi

    mov dword[0x70000],0x71007      ; First page directory entry
    mov dword[0x71000],10000111b    ; First page table entry

    lgdt [Gdt64Ptr]             ; Load GDT pointer

    mov eax,cr4                 ; Get cr4
    or eax,(1<<5)               ; Enable PAE
    mov cr4,eax                 ; Set cr4

    mov eax,0x70000             ; Get page directory base
    mov cr3,eax                 ; Set PDBR

    mov ecx,0xc0000080          ; Get EFER MSR address
    rdmsr                       ; Read EFER MSR
    or eax,(1<<8)               ; Enable long mode
    wrmsr                       ; Write EFER MSR

    mov eax,cr0                 ; Get cr0
    or eax,(1<<31)              ; Enable paging
    mov cr0,eax                 ; Set cr0

    jmp 8:LMEntry               ; Switch to long mode

; @label:     PEnd
; @brief:     Halts the CPU and creates an infinite loop in protected mode.
;
; @return:    None. This label does not return any value.
;
PEnd:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp PEnd                    ; Jump to 'PEnd' label in infinite loop

[BITS 64]                       ; Use 64-bit mode

; @label:     LMEntry
; @brief:     Entry point for long mode.
;
; @param:     rsp   A register that holds the stack pointer address (0x7c00).
; @param:     rdi   A register that holds the new destination address for the
;                   kernel (0x200000).
; @param:     rsi   A register that holds the old destination address for the
;                   kernel (0x10000).
; @param:     rcx   A register that holds the number of quadwords to move
;                   (51200/8).
;
; @return:    None. This label sets the stack pointer, relocates the kernel to a
;             higher memory address, and jumps to the kernel entry point.
;
LMEntry:                        ; Entry point for long mode
    mov rsp,0x7c00              ; Stack pointer

    cld                         ; Increment rdi after store
    mov rdi,0x200000            ; New destination for Kernel
    mov rsi,0x10000             ; Old destination for Kernel
    mov rcx,51200/8             ; 512B * 100 sectors / 8
    rep movsq                   ; Quadwords move (reloacte kernel)

    jmp 0x200000                ; Jump to kernel

; @brief:     Halts the CPU and creates an infinite loop in long mode.
;
; @return:    None. This label does not return any value.
;
LEnd:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp LEnd                    ; Jump to 'LEnd' label in infinite loop
;
; @var:       DriveId
;
; @brief:     A byte variable that stores the drive ID from which the program
;             was loaded.
DriveId:    db 0            ; Byte for DriveId

; @var:       ReadPacket
;
; @brief:     A 16-byte structure that contains the parameters for the disk
;             read operation in extended mode.
;
ReadPacket: times 16 db 0   ; Allocate 16B, for storing a packet from the disk

; @var:       Gdt32
;
; @brief:     A 32-bit GDT descriptor that contains the code and data segment
;             descriptors for protected mode.
;
Gdt32:                      ; 32-bit GDT descriptor, zero-initialized
    dq 0
Code32:                     ; 32-bit code segment descriptor
    dw 0xffff               ; limit=64K
    dw 0                    ; base=0
    db 0                    ; base=0
    db 0x9a                 ; access=0x9a
    db 0xcf                 ; flags=0xcf
    db 0                    ; upper 8 bits of base address
Data32:                     ; 32-bit data segment descriptor
    dw 0xffff               ; limit=64K
    dw 0                    ; base=0
    db 0                    ; base=0
    db 0x92                 ; access=0x92
    db 0xcf                 ; flags=0xcf
    db 0                    ; upper 8 bits of base address

; @var:       Gdt32Len
;
; @brief:     A constant that holds the length of the Gdt32 descriptor.
;
Gdt32Len: equ $-Gdt32       ; Length of Gdt32

; @var:       Gdt32Ptr
;
; @brief:     A 6-byte structure that contains the length and address of the
;             Gdt32 descriptor.
;
Gdt32Ptr: dw Gdt32Len-1     ; (Length of Gdt32)-1
          dd Gdt32          ; Address of Gdt32

; @var:       Idt32Ptr
;
; @brief:     A 6-byte structure that contains the length and address of the
;             Idt32 descriptor.
;
Idt32Ptr: dw 0              ; Length of Idt32
          dd 0              ; Address of Idt32

; @var:       Gdt64
;
; @brief:     A 64-bit GDT descriptor that contains the code segment
;             descriptor for long mode.
;
Gdt64:                      ; 64-bit GDT descriptor, zero-initialized
    dq 0
    dq 0x0020980000000000   ; Code segment descriptor

; @var:       Gdt64Len
;
; @brief:     A constant that holds the length of the Gdt64 descriptor.
;
Gdt64Len: equ $-Gdt64       ; Length of Gdt64

; @var:       Gdt64Ptr
;
; @brief:     A 10-byte structure that contains the length and address of the
;             Gdt64 descriptor.
;
Gdt64Ptr: dw Gdt64Len-1     ; (Length of Gdt64)-1
          dd Gdt64          ; Address of Gdt64
