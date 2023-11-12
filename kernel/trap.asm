;------------------------------------------------------------------------------
; @file:        trap.asm
; @author:      Marko Trickovic (marko.trickovic@outlook.com)
; @date:        11/12/2023 10:34 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This file contains the assembly code for trap handling. It
;               defines the global symbols for the interrupt vectors and the
;               functions to send end of interrupt service register, and load
;               the interrupt descriptor table pointer.
;
;               It also defines the Trap and TrapReturn macros that save and
;               restore the CPU registers and call the handler function in C.
;
;               The handler function is defined in trap.c and takes a pointer to
;               the trap frame.
;
;               The trap frame is a data structure that stores the state of the
;               CPU registers when a trap (an exception or an interrupt) occurs.
;
; Revision History:
;
;   - Revision 0.1: 11/06/2023 Marko Trickovic
;     Initial version that defines trap handling functions.
;
;   - Revision 0.2: 11/12/2023 Marko Trickovic
;     Refactored (added) the comments to improve readability.
;
; Part of the os-dev-udemy-wsl.
;------------------------------------------------------------------------------

section .text
extern handler
global vector0
global vector1
global vector2
global vector3
global vector4
global vector5
global vector6
global vector7
global vector8
global vector10
global vector11
global vector12
global vector13
global vector14
global vector16
global vector17
global vector18
global vector19
global vector32
global vector39
global eoi
global read_isr
global load_idt

; @routine:  Trap
; @brief:    This function handles the interrupts and exceptions by saving the
;            registers, calling the handler, and restoring the registers.
;
; @param:    rax   The rax register before the interrupt or exception occurred.
; @param:    rbx   The rbx register before the interrupt or exception occurred.
; @param:    rcx   The rcx register before the interrupt or exception occurred.
; @param:    rdx   The rdx register before the interrupt or exception occurred.
; @param:    rsi   The rsi register before the interrupt or exception occurred.
; @param:    rdi   The rdi register before the interrupt or exception occurred.
; @param:    rbp   The rbp register before the interrupt or exception occurred.
; @param:    r8    The r8 register before the interrupt or exception occurred.
; @param:    r9    The r9 register before the interrupt or exception occurred.
; @param:    r10   The r10 register before the interrupt or exception occurred.
; @param:    r11   The r11 register before the interrupt or exception occurred.
; @param:    r12   The r12 register before the interrupt or exception occurred.
; @param:    r13   The r13 register before the interrupt or exception occurred.
; @param:    r14   The r14 register before the interrupt or exception occurred.
; @param:    r15   The r15 register before the interrupt or exception occurred.
;
; @return          None
;
Trap:
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

    inc byte[0xb8010]
    mov byte[0xb8011],0xe

    mov rdi,rsp
    call handler

TrapReturn:
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

    add rsp,16
    iretq

; @routine:   vector0
; @brief:     This routine is the entry point for the divide by zero exception.
; @param:     No parameters are passed to this function.
vector0:
    push 0
    push 0
    jmp Trap

; @routine:   vector1
; @brief:     This routine is the entry point for the debug exception.
; @param:     No parameters are passed to this function.
vector1:
    push 0
    push 1
    jmp Trap

; @routine:   vector2
; @brief:     This routine is the entry point for the non-maskable interrupt.
; @param:     No parameters are passed to this function.
vector2:
    push 0
    push 2
    jmp Trap

; @routine:   vector3
; @brief:     This routine is the entry point for the breakpoint exception.
; @param:     No parameters are passed to this function.
vector3:
    push 0
    push 3	
    jmp Trap

; @routine:   vector4
; @brief:     This routine is the entry point for the overflow exception.
; @param:     No parameters are passed to this function.
vector4:
    push 0
    push 4	
    jmp Trap   

; @routine:   vector5
; @brief:     This routine is the entry point for the bound range exceeded
;             exception.
; @param:     No parameters are passed to this function.
vector5:
    push 0
    push 5
    jmp Trap

; @routine:   vector6
; @brief:     This routine is the entry point for the invalid opcode exception.
; @param:     No parameters are passed to this function.
vector6:
    push 0
    push 6	
    jmp Trap      

; @routine:   vector7
; @brief:     This routine is the entry point for the device not available
;             exception.
; @param:     No parameters are passed to this function.
vector7:
    push 0
    push 7	
    jmp Trap  

; @routine:   vector8
; @brief:     This routine is the entry point for the double fault exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector8:
    push 8
    jmp Trap  

; @routine:   vector10
; @brief:     This routine is the entry point for the invalid TSS exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector10:
    push 10	
    jmp Trap 

; @routine:   vector11
; @brief:     This routine is the entry point for the segment not present
;             exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector11:
    push 11	
    jmp Trap

; @routine:   vector12
; @brief:     This routine is the entry point for the stack-segment fault
;             exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector12:
    push 12	
    jmp Trap          

; @routine:   vector13
; @brief:     This routine is the entry point for the general protection fault
;             exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector13:
    push 13
    jmp Trap

; @routine:   vector14
; @brief:     This routine is the entry point for the page fault exception.
; @param:     The error code is pushed on the stack before calling this
;             function.
vector14:
    push 14	
    jmp Trap 

; @routine:   vector16
; @brief:     This routine is the entry point for the x87 FPU floating-point
;             error exception.
; @param:     No parameters are passed to this function.
vector16:
    push 0
    push 16
    jmp Trap

; @routine:   vector17
; @brief:     This routine is the entry point for the alignment check exception.
; @param:     The error code is pushed on the stack before calling this function.
vector17:
    push 17	
    jmp Trap                         

; @routine:   vector18
; @brief:     This function is the entry point for the machine check exception.
; @param:     No parameters are passed to this function.
vector18:
    push 0
    push 18	
    jmp Trap 

; @routine:   vector19
; @brief:     This function is the entry point for the SIMD floating-point
;             exception.
; @param:     No parameters are passed to this function.
vector19:
    push 0
    push 19	
    jmp Trap

; @routine:   vector32
; @brief:     This function is the entry point for the timer interrupt.
; @param:     No parameters are passed to this function.
vector32:
    push 0
    push 32
    jmp Trap

; @routine:   vector39
; @brief:     This function is the entry point for the keyboard interrupt.
; @param:     No parameters are passed to this function.
vector39:
    push 0
    push 39
    jmp Trap

; @routine:   eoi
; @brief:     This function sends an end-of-interrupt signal to the PIC.
; @param:     No parameters are passed to this function.
; @return:    None.
eoi:
    mov al,0x20
    out 0x20,al
    ret

; @routine:   read_isr
; @brief:     This function reads the in-service register of the PIC.
; @param:     No parameters are passed to this function.
; @return:    The value of the in-service register is stored in al.
read_isr:
    mov al,11
    out 0x20,al
    in al,0x20
    ret

; @routine:   load_idt
; @brief:     This function loads the IDT from a given address.
; @param:     The address of the IDT is passed in rdi.
; @return:    None.
load_idt:
    lidt [rdi]
    ret
