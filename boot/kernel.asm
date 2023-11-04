;------------------------------------------------------------------------------
; @file:        kernel.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        11/04/2023 11:55 PM
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
;                   - The timer handler increments the ASCII code of the third
;                     character on the screen and sets its attribute to 0xE,
;                     which is yellow-on-black.
;
;                   - The expected output is a changing character in white and
;                     yellow colors on the top right corner of the screen,
;                     every 10 milliseconds.
;
;                   - Jumps to the user entry point in ring 3 and increments
;                     the ASCII code of the second char in white color to the
;                     video memory.
;
;                   - Switches to ring 3 by pushing the values for CS, RFLAGS,
;                     offset, interrupt number, DS, and UserEntry address on
;                     the stack and returning from interrupt.
;
;                   - Added a TSS descriptor definition for the current task.
;
;                   - Added a code snippet to set the TSS descriptor in the GDT
;                     and load the TR with the TSS selector.
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
; Revision 0.4: 10/31/2023 Marko Trickovic
; Define and use push/pop macros in interrupt handlers.
;
; Revision 0.5: 10/31/2023 Marko Trickovic
; Set up and test timer interrupt handler in 64-bit kernel.
;
; Revision 0.6: 11/01/2023 Marko Trickovic
; Added the code for switching to ring 3 and jumping to the UserEntry point.
;
; Revision 0.7: 11/02/2023 Marko Trickovic
; Revised the code to add TSS support.
;
; Revision 0.8: 11/04/2023 Marko Trickovic
; Modified UserEntry function and timer interrupt handler to increment the
; ASCII code of the second and third characters on the screen, respectively.
;
; Revision 0.9: 11/04/2023 Marko Trickovic
; Implemented the SetHandler function that sets up an interrupt handler in
; the IDT.
; Implemented the spurious interrupt handler that checks if a spurious
; interrupt has occurred and acknowledges it.
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

; start Label
; Purpose: Sets up the interrupt handling mechanism and switches to 64-bit mode
; Parameters: None
; Return Value: None
; Registers Used: rdi, rax
; Flags Modified: None
; Assumptions: None
; Side Effects: None
start:
    mov rdi,Idt                 ; Load IDT base address into rdi

    mov rax,Handler0            ; Set the first IDT entry to point to Handler0
    call SetHandler

    mov rax,Timer               ; Set the second IDT entry to point to Timer
    mov rdi,Idt+32*16
    call SetHandler

    mov rdi,Idt+32*16+7*16      ; Move to the seventh IDT entry
    mov rax,SIRQ                ; Set the third IDT entry to point to SIRQ
    call SetHandler

    lgdt [Gdt64Ptr]             ; Load GDT pointer
    lidt [IdtPtr]               ; Load IDT pointer

; SetTss Routine
; Purpose: Sets up the Task State Segment (TSS) descriptor in the GDT and
; loads the TR with the TSS selector
; Parameters: None
; Return Value: None
; Registers Used: rax, ax
; Flags Modified: None
; Assumptions: None
; Side Effects: Switches to 64-bit mode and jumps to the kernel entry point
SetTss:
    mov rax,Tss                 ; Base address of TSS to RAX
    mov [TssDesc+2],ax          ; Low 16 bits of RAX to bytes 2 and 3
    shr rax,16                  ; Shift RAX right by 16 bits
    mov [TssDesc+4],al          ; Low 8 bits of RAX to byte 4
    shr rax,8                   ; Shift RAX right by 8 bits
    mov [TssDesc+7],al          ; Low 8 bits of RAX to byte 7
    shr rax,8                   ; Shift RAX right by 8 bits
    mov [TssDesc+8],eax         ; Low 32 bits of RAX to bytes 8 to 11

    mov ax,0x20                 ; Segment selector for TSS descriptor to AX
    ltr ax                      ; Load TR with AX

    push 8                      ; Push the code segment selector
    push KernelEntry            ; Push the kernel entry point address
    db 0x48                     ; Use the REX prefix to indicate 64-bit operand
    retf                        ; Return far

KernelEntry:
    mov byte[0xb8000],'K'       ; Write 'K' to video memory
    mov byte[0xb8001],0xa       ; Green color

; Routine: InitPIT
; Purpose: Sets up the Programmable Interval Timer (PIT) mode and frequency
; Parameters: None
; Return Value: None
; Registers Used: al, ax
; Flags Modified: None
; Assumptions: None
; Side Effects: Generates periodic timer interrupts at 100 Hz
InitPIT:                        ; Set PIT mode and frequency
    mov al,(1<<2)|(3<<4)        ; Rate generator, low/high
    out 0x43,al                 ; Command byte to PIT port

    mov ax,11931                ; Reload value for 100 Hz
    out 0x40,al                 ; Low byte to PIT channel 0 port
    mov al,ah                   ; High byte to al
    out 0x40,al                 ; High byte to PIT channel 0 port

; Routine: InitPIC
; Purpose: Sets up the Programmable Interrupt Controller (PIC) mode and mapping
; Parameters: None
; Return Value: None
; Registers Used: al
; Flags Modified: None
; Assumptions: None
; Side Effects: Enables the timer interrupt and switches to user mode
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

    push 0x18|3                 ; long mode CS and RFLAGS
    push 0x7c00                 ; user entry offset
    push 0x202                  ; interrupt number for iretq
    push 0x10|3                 ; protected mode DS and reserved
    push UserEntry              ; UserEntry address
    iretq                       ; Return from interrupt/exception to user mode

End:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp End                     ; Jump to 'End' label in infinite loop

; Function: SetHandler
;
; Purpose: Sets up an interrupt handler in the IDT (Interrupt Descriptor Table)
; Parameters: rdi - address of the IDT entry, ax - lower 16 bits of handler
; address
; The function takes a 64-bit handler address in rax and updates the IDT entry
; pointed to by rdi.
SetHandler:
    mov [rdi],ax                ; Store lower 16 bits of handler address
    shr rax,16                  ; Shift right handler address by 16 bits
    mov [rdi+6],ax              ; Store middle 16 bits of handler address
    shr rax,16                  ; Shift right handler address by 16 more bits
    mov [rdi+8],eax             ; Store highest 32 bits of handler address
    ret                         ; Return from function

UserEntry:
    inc byte[0xb8010]           ; Increment ASCII code of second char
    mov byte[0xb8011],0xF       ; move 0xF (white on black) to the video memory

UEnd:
    jmp UserEntry               ; loop indefinitely

Handler0:
    push_regs                   ; Save the registers
    mov byte[0xb8000],'D'       ; Write 'D' to video memory
    mov byte[0xb8001],0xc       ; Red color

    jmp End                     ; Jump to 'End' label in infinite loop

    pop_regs                    ; Restore the rsegisters
    iretq                       ; Return from interrupt/exception to user mode

Timer:
    push_regs                   ; Save the registers
    inc byte[0xb8020]           ; Increment ASCII code of third char
    mov byte[0xb8021],0xe       ; Set attribute to yellow-on-black

    mov al,0x20                 ; Move EOI code to AL
    out 0x20,al                 ; Send EOI to PIC

    pop_regs                    ; Restore the registers
    iretq                       ; Return from interrupt/exception to user mode

; SIRQ Routine
; Purpose: Checks if a spurious interrupt has occurred and acknowledges it
; Parameters: None
; Return Value: None
; Registers Used: al
; Flags Modified: None
; Assumptions: None
; Side Effects: None
SIRQ:
    push_regs                   ; Save the registers on the stack

    mov al,11                   ; Move 11 to al
    out 0x20,al                 ; Send the EOI command to the master PIC
    in al,0x20                  ; Read the ISR from the master PIC

    test al,(1<<7)              ; Test if the highest bit of ISR is set
    jz .end                     ; If not, jump to the end of the routine

    mov al,0x20                 ; Move 0x20 to al
    out 0x20,al                 ; Send the EOI command again to the master PIC

.end:
    pop_regs                    ; Restore the registers from the stack
    iretq                       ; Return from interrupt

; This code defines a 64-bit GDT descriptor, which is a table that contains
; information about the segments and tasks in the system.
; The GDT descriptor has four entries:
; - Null entry: this entry is required and must be zero.
; - Code segment: this entry defines the code segment for long mode, which is
;   the 64-bit operating mode of the processor.
; - Data segment: this entry defines the data segment for long mode, which is
;   where the program data is stored.
; - TSS segment: this entry defines the task state segment (TSS) for long mode,
;   which is a structure that holds information about a task, such as processor
;   register state, I/O port permissions, inner-level stack pointers, and
;   previous TSS link.
; The TSS segment entry has the following fields:
; - Limit: the 16-bit size of the TSS.
; - Base: the 64-bit linear base address of the TSS.
; - Type: the type of the TSS, either 9 for non-busy or 11 for busy.
; - DPL: the descriptor privilege level, which determines who can access the
; TSS descriptor.
; - P: the present bit, which indicates whether the TSS is in memory or not.
; - G: the granularity bit, which determines how the limit is interpreted.
Gdt64:                          ; 64-bit GDT descriptor, zero-initialized
    dq 0                        ; Null entry, required
    dq 0x0020980000000000       ; Long mode code segment, ring 0
    dq 0x0020f80000000000       ; Long mode data segment, ring 0
    dq 0x0000f20000000000       ; Long mode TSS segment, ring 0
TssDesc:
    dw TssLen-1                 ; Limit of TSS
    dw 0                        ; Base of TSS (low)
    db 0                        ; Base of TSS (middle)
    db 0x89                     ; Type (9), DPL (0), P (1)
    db 0                        ; Limit (high), G (0)
    db 0                        ; Base of TSS (high)
    dq 0                        ; Base of TSS (upper)


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


; TSS descriptor for current task
; TSS holds info about a task, e.g. registers, I/O, stacks, link
; - Base: 32-bit linear address of TSS
; - Limit: 20-bit size of TSS
; - Type: 9 for non-busy or 11 for busy
; - DPL: privilege level of descriptor
; - P: present bit, 1 if TSS in memory
; - G: granularity bit, how limit is interpreted
; More info:
Tss:
    dd 0                        ; First 32 bits reserved, zero
    dq 0x150000                 ; Next 64 bits are base address
    times 88 db 0               ; Next 88 bytes reserved, zero
    dd TssLen                   ; Last 32 bits are limit

TssLen: equ $-Tss               ; Label for size of TSS
