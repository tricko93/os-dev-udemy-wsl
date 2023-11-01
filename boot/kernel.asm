;------------------------------------------------------------------------------
; @file:        kernel.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/31/2023 09:45 PM
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
;               The code does the following:
;
;                   - Sets up the Global Descriptor Table (GDT) and the
;                     Interrupt Descriptor Table (IDT) for handling interrupts
;                     and exceptions.
;
;                   - Switches to 64-bit mode and writes 'K' in green color to
;                     the video memory.
;
;                   - Initializes the Programmable Interval Timer (PIT) and the
;                     Programmable Interrupt Controller (PIC) to generate
;                     periodic timer interrupts.
;
;                   - Defines two handler functions: one for the divide by 0
;                     exception and one for the timer interrupt.
;
;                   - The divide by 0 handler writes 'D' in red color to the
;                     video memory and halts the CPU.
;
;                   - The timer handler writes 'T' in yellow color to the video
;                     memory and returns from the interrupt.
;
;                   - The expected output is 'KT' in green and yellow colors on
;                     the screen, every 10 milliseconds.
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
;
; Revision 0.4  10/31/2023  Marko Trickovic
; Define and use push/pop macros in interrupt handlers.
;
; Revision 0.5  10/31/2023  Marko Trickovic
; Set up and test timer interrupt handler in 64-bit kernel.
;------------------------------------------------------------------------------

[BITS 64]                       ; Use 64-bit mode
[ORG 0x200000]                  ; Set origin to Kernel address

%macro push_regs 0              ; Define macro for saving the registers
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro pop_regs 0               ; Define macro for restoring the registers
    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax
%endmacro

start:
    mov rdi,Idt                 ; Load IDT base address into rdi

    mov rax,Handler0            ; Set the first IDT entry to point to Handler0
    mov [rdi],ax                ; Store low 16 bits of Handler0
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+6],ax              ; Store mid 16 bits of Handler0
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+8],eax             ; Store high 32 bits of Handler0

    mov rax,Timer               ; Set the second IDT entry to point to Timer
    add rdi,32*16
    mov [rdi],ax                ; Store low 16 bits of Timer
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+6],ax              ; Store mid 16 bits of Timer
    shr rax,16                  ; Shift rax right by 16 bits
    mov [rdi+8],eax             ; Store high 32 bits of Timer

    lgdt [Gdt64Ptr]             ; Load GDT pointer
    lidt [IdtPtr]               ; Load IDT pointer

    push 8                      ; Push the code segment selector
    push KernelEntry            ; Push the kernel entry point address
    db 0x48                     ; Use the REX prefix to indicate 64-bit operand
    retf                        ; Return far

KernelEntry:
    mov byte[0xb8000],'K'       ; Write 'K' to video memory
    mov byte[0xb8001],0xa       ; Green color

InitPIT:                        ; Set PIT mode and frequency
    mov al,(1<<2)|(3<<4)        ; Rate generator, low/high
    out 0x43,al                 ; Command byte to PIT port

    mov ax,11931                ; Reload value for 100 Hz
    out 0x40,al                 ; Low byte to PIT channel 0 port
    mov al,ah                   ; High byte to al
    out 0x40,al                 ; High byte to PIT channel 0 port

InitPIC:                        ; Set PIC mode and mapping
    mov al,0x11                 ; Start init, use ICW4, edge triggered
    out 0x20,al                 ; ICW1 to master PIC port
    out 0xa0,al                 ; ICW1 to slave PIC port

    mov al,32                   ; Map IRQ0-7 to INT 20h-27h for master PIC
    out 0x21,al                 ; ICW2 to master PIC port
    mov al,40                   ; Map IRQ8-15 to INT 28h-2Fh for slave PIC
    out 0xa1,al                 ; ICW2 to slave PIC port

    mov al,4                    ; Connect IRQ2 of master PIC to slave PIC
    out 0x21,al                 ; ICW3 to master PIC port
    mov al,2                    ; Connect slave PIC to IRQ2 of master PIC
    out 0xa1,al                 ; ICW3 to slave PIC port

    mov al,1                    ; Use 8086 mode for both PICs
    out 0x21,al                 ; ICW4 to master PIC port
    out 0xa1,al                 ; ICW4 to slave PIC port

    mov al,11111110b            ; Only IRQ0 (timer) on for master PIC
    out 0x21,al                 ; IMR to master PIC port
    mov al,11111111b            ; Disable all IRQs for slave PIC
    out 0xa1,al                 ; IMR to slave PIC port

    sti                         ; Enable interrupts

End:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp End                     ; Jump to 'End' label in infinite loop

Handler0:
    push_regs                   ; Save the registers
    mov byte[0xb8000],'D'       ; Write 'D' to video memory
    mov byte[0xb8001],0xc       ; Red color

    jmp End                     ; Jump to 'End' label in infinite loop

    pop_regs                    ; Restore the registers

    iretq

Timer:
    push_regs                   ; Save the registers
    mov byte[0xb8020],'T'       ; Write 'T' to video memory
    mov byte[0xb8021],0xe
    jmp End                     ; Jump to 'End' label in infinite loop

    pop_regs                    ; Restore the registers

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
