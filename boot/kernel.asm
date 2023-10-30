;------------------------------------------------------------------------------
; @file:        kernel.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/30/2023 10:50 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This is a 64-bit assembly code that loads a Global Descriptor
;               Table (GDT) and jumps to a kernel entry point. The code uses
;               the NASM syntax and sets the origin to 0x200000, which is the
;               address where the kernel is loaded by the bootloader. The code
;               first loads the GDT pointer using the lgdt instruction, which
;               takes a 48-bit operand consisting of a 16-bit limit and a
;               32-bit base address. The code then pushes the code segment
;               selector (8) and the kernel entry point address (KernelEntry)
;               on the stack, and uses a far return instruction (retf) to jump
;               to the kernel code segment.
;               The kernel entry point writes a character ‘K’ with a green
;               color to the video memory at address 0xB8000, which is the
;               start of the VGA text mode buffer. The code then enters an
;               infinite loop of halting the CPU until an external interrupt
;               occurs, and then jumping back to the halt instruction.
;
; Usage: make
;
; Revision History:
;
; Revision 0.1: 10/30/2023 Marko Trickovic
; Initial creation of the Kernel assembly program.
;
; Revision 0.2: 10/30/2023  Marko Trickovic
; Reload GDT and switch to 64-bit mode.
; -----------------------------------------------------------------------------

[BITS 64]                       ; Use 64-bit mode
[ORG 0x200000]                  ; Set origin to Kernel address

start:
    lgdt [Gdt64Ptr]             ; Load GDT pointer

    push 8                      ; Push the code segment selector
    push KernelEntry            ; Push the kernel entry point address
    db 0x48                     ; Use the REX prefix to indicate 64-bit operand
    retf                        ; Return far

KernelEntry:
    mov byte[0xb8000],'K'       ; Write 'K' to video memory
    mov byte[0xb8001],0xa       ; Green color

End:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp End                     ; Jump to 'End' label in infinite loop

Gdt64:                          ; 64-bit GDT descriptor, zero-initialized
    dq 0
    dq 0x0020980000000000       ; Code segment descriptor

Gdt64Len: equ $-Gdt64           ; Length of Gdt64

Gdt64Ptr: dw Gdt64Len-1         ; (Length of Gdt64)-1
          dd Gdt64              ; Address of Gdt64
