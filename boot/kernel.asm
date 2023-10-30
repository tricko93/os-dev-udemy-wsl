;------------------------------------------------------------------------------
; @file:        kernel.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/30/2023 11:57 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This is the source code file for the kernel of a 64-bit
;               operating system. The code sets up the Global Descriptor Table
;               (GDT) and the Interrupt Descriptor Table (IDT) for handling
;               interrupts and exceptions and jumps to a kernel entry point.
;               The NASM syntax is used, and the origin is set to 0x200000, the
;               address where the bootloader loads the kernel.
;               The code also switches to 64-bit mode and writes ‘K’ in green
;               color to the video memory.
;
;               The code initializes the GDT pointer using the lgdt
;               instruction, which takes a 48-bit operand consisting of a
;               16-bit limit and a 32-bit base address. Subsequently, the code
;               pushes the code segment selector (8) and the kernel entry point
;               address (KernelEntry) onto the stack. A far return instruction
;               (retf) is used to jump to the kernel code segment.
;
;               The kernel entry point writes a character 'K' with a green
;               color to the video memory at address 0xB8000, the start of the
;               VGA text mode buffer. The code then enters an infinite loop of
;               halting the CPU until an external interrupt occurs, and then
;               jumping back to the halt instruction.
;
;               Note: The intentional divide-by-zero exception is triggered
;               in this code to test interrupt handling. The 'End' label
;               contains a divide by zero operation (div rbx), leading to a
;               divide-by-zero exception. The exception is handled by the IDT,
;               and the kernel responds appropriately by printing character 'D'.
;
; Usage: make
;
; Revision History:
;
; Revision 0.1: 10/30/2023 Marko Trickovic
; Initial creation of the Kernel assembly program.
;
; Revision 0.2: 10/30/2023 Marko Trickovic
; Reload GDT and switch to 64-bit mode.
;
; Revision 0.3: 10/30/2023 Marko Trickovic
; Set up and load IDT. Implement and test divide by 0 exception handling.
;------------------------------------------------------------------------------

[BITS 64]                       ; Use 64-bit mode
[ORG 0x200000]                  ; Set origin to Kernel address

start:
    mov rdi,Idt                 ; Set the first IDT entry to point to Handler0
    mov rax,Handler0            ; Load IDT base address into rdi

    mov [rdi],ax                ; Store low 16 bits of Handler0
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+6],ax              ; Store mid 16 bits of Handler0
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+8],eax             ; Store high 32 bits of Handler0

    lgdt [Gdt64Ptr]             ; Load GDT pointer
    lidt [IdtPtr]               ; Load IDT pointer

    push 8                      ; Push the code segment selector
    push KernelEntry            ; Push the kernel entry point address
    db 0x48                     ; Use the REX prefix to indicate 64-bit operand
    retf                        ; Return far

KernelEntry:
    mov byte[0xb8000],'K'       ; Write 'K' to video memory
    mov byte[0xb8001],0xa       ; Green color

    xor rbx,rbx                 ; Zero RBX
    div rbx                     ; Divide by 0 to generate interrupt

End:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp End                     ; Jump to 'End' label in infinite loop

Handler0:
    mov byte[0xb8000],'D'       ; Write 'D' to video memory
    mov byte[0xb8001],0xc       ; Red color

    jmp End                     ; Jump to 'End' label in infinite loop

    iretq

Gdt64:                          ; 64-bit GDT descriptor, zero-initialized
    dq 0
    dq 0x0020980000000000       ; Code segment descriptor

Gdt64Len: equ $-Gdt64           ; Length of Gdt64


Gdt64Ptr: dw Gdt64Len-1         ; (Length of Gdt64)-1
          dq Gdt64              ; Address of Gdt64


Idt:                            ; IDT descriptor
    %rep 256                    ; Define 256 IDT entries, each 16 bytes long
        dw 0                    ; Offset low
        dw 0x8                  ; Selector (code segment)
        db 0                    ; IST (stack index)
        db 0x8e                 ; Type and attributes
        dw 0                    ; Offset middle
        dd 0                    ; Offset high
        dd 0                    ; Reserved
    %endrep

IdtLen: equ $-Idt               ; Length of IDT

IdtPtr: dw IdtLen-1             ; Length of IDT-1
        dq Idt                  ; Address of Idt
