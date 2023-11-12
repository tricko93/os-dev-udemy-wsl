;------------------------------------------------------------------------------
; @file:        kernel.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        11/12/2023 10:34 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This is the source code file for the kernel of a 64-bit
;               operating system.
;
;               The code does the following:
;
;                   - Set up the Global Descriptor Table (GDT).
;
;                   - Added a TSS descriptor definition for the current task.
;
;                   - Added a code snippet to set the TSS descriptor in the GDT
;                     and load the TR with the TSS selector.
;
;                   - Switches to 64-bit mode and calls KMain function.
;
;                   - Initializes the Programmable Interval Timer (PIT) and the
;                     Programmable Interrupt Controller (PIC) to generate
;                     periodic timer interrupts.
;
;                   - Switches to ring 3 by pushing the values for CS, RFLAGS,
;                     offset, interrupt number, DS, and UserEntry address on
;                     the stack and returning from interrupt.
;
;                   - Compile kernel.asm as elf64 and update code accordingly.
;
;                   - Call KMain function from kernel.asm at physical address
;                     0x200000.
;
; Usage: make
;
; Revision History:
;
;   - Revision 0.1: 10/30/2023 Marko Trickovic
;     Initial creation of the Kernel assembly program.
;
;   - Revision 0.2: 10/30/2023 Marko Trickovic
;     Reload GDT and switch to 64-bit mode.
;
;   - Revision 0.3: 10/30/2023 Marko Trickovic
;     Set up and load IDT. Implement and test divide by 0 exception handling.
;
;   - Revision 0.4: 10/31/2023 Marko Trickovic
;     Define and use push/pop macros in interrupt handlers.
;
;   - Revision 0.5: 10/31/2023 Marko Trickovic
;     Set up and test timer interrupt handler in 64-bit kernel.
;
;   - Revision 0.6: 11/01/2023 Marko Trickovic
;     Added the code for switching to ring 3 and jumping to the UserEntry point.
;
;   - Revision 0.7: 11/02/2023 Marko Trickovic
;     Revised the code to add TSS support.
;
;   - Revision 0.8: 11/04/2023 Marko Trickovic
;     Modified UserEntry function and timer interrupt handler to increment the
;     ASCII code of the second and third characters on the screen, respectively.
;
;   - Revision 0.9: 11/04/2023 Marko Trickovic
;     Implemented the SetHandler function that sets up an interrupt handler in
;     the IDT.
;     Implemented the spurious interrupt handler that checks if a spurious
;     interrupt has occurred and acknowledges it.
;
;   - Revision 1.0: 11/05/2023 Marko Trickovic
;     Bootstrap C code from assembly.
;
;   - Revision 1.1: 11/06/2023 Marko Trickovic
;     Enable interrupts and set stack segment offset to 0.
;------------------------------------------------------------------------------

section .data

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

; @var:         Gdt32
;
; @brief:       A 64-bit GDT descriptor that contains the code and data segment
;               descriptors for protected mode.
;
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

; @var:         Gdt64Len
;
; @brief:       A constant that holds the length of the Gdt64 descriptor.
;
Gdt64Len: equ $-Gdt64           ; Length of Gdt64

; @var:         Gdt64Ptr
;
; @brief:       A 10-byte structure that contains the length and address of the
;               Gdt64 descriptor.
;
Gdt64Ptr: dw Gdt64Len-1         ; (Length of Gdt64)-1
          dq Gdt64              ; Address of Gdt64

; TSS descriptor for current task
; TSS holds info about a task, e.g. registers, I/O, stacks, link
; - Base: 32-bit linear address of TSS
; - Limit: 20-bit size of TSS
; - Type: 9 for non-busy or 11 for busy
; - DPL: privilege level of descriptor
; - P: present bit, 1 if TSS in memory
; - G: granularity bit, how limit is interpreted
; More info:

; @var:         Tss
;
; @brief:       A 64-bit task state segment (TSS) that holds information about
;               a task, such as processor register state, I/O port permissions,
;               inner-level stack pointers, and previous TSS link.
;
Tss:
    dd 0                        ; First 32 bits reserved, zero
    dq 0x150000                 ; Next 64 bits are base address
    times 88 db 0               ; Next 88 bytes reserved, zero
    dd TssLen                   ; Last 32 bits are limit

TssLen: equ $-Tss               ; Label for size of TSS

;
; @brief:       The section that contains the executable code of the program.
;
; @note:        The .text section is also known as the code segment.
;
section .text

; @directive:   extern
;
; @brief:       The directive that tells the assembler to look for the
;               definition of a symbol in another object file or library.
;
; @param:       KMain  The name of the symbol that is declared as external.
;
; @note:        The extern directive is used to link the program with other
;               modules or libraries that contain the definition of the symbol.
;
extern KMain                    ; Declare an external symbol named KMain

; @directive:   global
;
; @brief:       The directive that tells the assembler to make a symbol visible
;               to other object files or libraries.
;
; @param:       start  The name of the symbol that is declared as global.
;
; @note:        The global directive is used to export the symbol to the linker,
;               which can then resolve the references to the symbol from other
;               modules or libraries. The start symbol is usually the entry
;               point of the program.
global start                    ; Declare a global symbol named start

; @routine:     start
; @brief:       The entry point of the program, which sets up the processor and
;               the memory for the execution of the main program.
;
; @return:      None, as this routine does not return to the caller, but jumps
;               to the KMain routine, which is the main function of the kernel.
;
start:
    lgdt [Gdt64Ptr]             ; Load GDT pointer into the GDTR register

; @routine:     SetTss
; @brief:       Sets the base address and the segment selector of the TSS in the
;               TSS descriptor and the TR register.
;
; @param:       rax   The new base address of the TSS, a 64-bit value.
;
; @return:      None, as this routine does not return any value, but modifies
;               the TSS descriptor and the TR register.
;
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

; @routine:     InitPIT
; @brief:       Initializes the programmable interval timer (PIT) to generate
;               periodic interrupts at a specified frequency.
;
; @param:       al    The command byte that specifies the mode and access mode
;                     of the PIT channel 0.
;
; @return:      None, as this routine does not return any value, but configures
;               the PIT registers and ports.
;
InitPIT:                        ; Set PIT mode and frequency
    mov al,(1<<2)|(3<<4)        ; Rate generator, low/high
    out 0x43,al                 ; Command byte to PIT port

    mov ax,11931                ; Reload value for 100 Hz
    out 0x40,al                 ; Low byte to PIT channel 0 port
    mov al,ah                   ; High byte to al
    out 0x40,al                 ; High byte to PIT channel 0 port

; @routine:     InitPIC
; @brief:       Initializes the programmable interrupt controller (PIC) to
;               handle hardware interrupts from various devices.
;
; @param:       al    The byte value that is sent to the PIC ports to configure
;                     the PIC mode, mapping, and masking.
;
; @return:      None, as this routine does not return any value, but sets up the
;               PIC registers and ports.
;
InitPIC:                        ; Set PIC mode and mapping
    mov al,0x11                 ; Start init, use ICW4, edge triggered
    out 0x20,al                 ; ICW1 to master PIC port
    out 0xa0,al                 ; ICW1 to slave PIC port
    ; @note:       The ICW1 is the initialization command word 1, which tells
    ;              the PIC to start the initialization process and use the ICW4
    ;              to specify more details. The edge triggered mode means that
    ;              the PIC will respond to the rising edge of the interrupt
    ;              signal.

    mov al,32                   ; Map IRQ0-7 to INT 20h-27h for master PIC
    out 0x21,al                 ; ICW2 to master PIC port
    mov al,40                   ; Map IRQ8-15 to INT 28h-2Fh for slave PIC
    out 0xa1,al                 ; ICW2 to slave PIC port
    ; @note:       The ICW2 is the initialization command word 2, which tells
    ;              the PIC the base address of the interrupt vector for each
    ;              PIC. The IRQs are the interrupt requests from the devices,
    ;              and the INTs are the interrupt service routines in the IDT.
    ;              The master PIC handles IRQ0-7, and the slave PIC handles
    ;              IRQ8-15.

    mov al,4                    ; Connect IRQ2 of master PIC to slave PIC
    out 0x21,al                 ; ICW3 to master PIC port
    mov al,2                    ; Connect slave PIC to IRQ2 of master PIC
    out 0xa1,al                 ; ICW3 to slave PIC port
    ; @note:       The ICW3 is the initialization command word 3, which tells
    ;              the PIC how the master and slave PICs are connected. The
    ;              master PIC needs a bit mask to indicate which IRQ is
    ;              connected to the slave PIC, and the slave PIC needs a number
    ;              to indicate which IRQ of the master PIC it is connected to.

    mov al,1                    ; Use 8086 mode for both PICs
    out 0x21,al                 ; ICW4 to master PIC port
    out 0xa1,al                 ; ICW4 to slave PIC port
    ; @note:       The ICW4 is the initialization command word 4, which tells
    ;              the PIC some additional details about the operation mode. The
    ;              8086 mode means that the PIC will use the 8086 interrupt
    ;              sequence.

    mov al,11111110b            ; Only IRQ0 (timer) on for master PIC
    out 0x21,al                 ; IMR to master PIC port
    mov al,11111111b            ; Disable all IRQs for slave PIC
    out 0xa1,al                 ; IMR to slave PIC port
    ; @note:       The IMR is the interrupt mask register, which tells the PIC
    ;              which IRQs are enabled or disabled. A 1 means disabled, and a
    ;              0 means enabled. The timer is the only device that is enabled
    ;              for the master PIC, and all devices are disabled for the
    ;              slave PIC.

    push 8                      ; Push the code segment selector onto the stack
    push KernelEntry            ; Push the KernelEntry point onto the stack
    db 0x48                     ; Encode a REX.W prefix to use 64-bit operands
    retf                        ; Return to 64-bit KernelEntry
    ; @note:       The code segment selector is 8, which is the index of the
    ;              code segment descriptor in the GDT. The KernelEntry is the
    ;              label of the entry point of the kernel. The REX.W prefix is
    ;              used to override the default operand size of 32 bits to 64
    ;              bits. The retf instruction is the far return, which pops the
    ;              code segment selector and the offset from the stack and jumps
    ;              to the 64-bit KernelEntry.

; @routine:     KernelEntry
; @brief:       The entry point of the kernel, which sets up the stack and the
;               long mode for the processor.
;
; @param:       ax    The register that is used to clear and set the stack
;                     segment selector and the stack pointer.
; @param:       ss    The stack segment selector that is used to access the
;                     stack.
;
; @return:      None, as this routine does not return to the caller, but jumps
;               to the KMain routine, which is the main function of the kernel.
;
KernelEntry:
    xor ax,ax                   ; Clear AX
    mov ss,ax                   ; Set SS to 0
    ; @note:       The stack segment selector is cleared to 0, which means that
    ;              the stack segment descriptor in the GDT is used. The stack
    ;              segment descriptor has a base address of 0 and a limit of
    ;              0xFFFFFFFF, which means that the stack can use the entire
    ;              4 GB of memory.

    mov rsp,0x200000            ; Adjust Kernel stack pointer
    ; @note:       The stack pointer is set to 0x200000, which is the top of the
    ;              kernel stack. The kernel stack grows downward from this
    ;              address. The kernel stack is separate from the boot stack,
    ;              which is used by the boot-loader and the assembly code.

    call KMain                  ; Call the KMain function (in C file)
    ; @note:       The KMain function is the main function of the kernel, which
    ;              is written in C. The KMain function performs the main tasks
    ;              of the kernel, such as initializing the memory manager, the
    ;              scheduler, the drivers, and the system calls.

    sti                         ; Enable interrupts
    ; @note:       The sti instruction sets the interrupt flag in the RFLAGS
    ;              register, which enables the processor to handle hardware and
    ;              software interrupts. Interrupts are disabled by default in
    ;              long mode, which is the 64-bit operating mode of the
    ;              processor.

; @label:     End
; @brief:     Halts the CPU and creates an infinite loop.
;
; @return:    None. This label does not return any value.
;
End:
    hlt                         ; Halt CPU until external interrupt jmp
    jmp End                     ; Jump to 'End' label in infinite loop
