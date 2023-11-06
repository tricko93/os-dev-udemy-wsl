/* -----------------------------------------------------------------------------
 * @file:        trap.h
 * @author:      Marko Trickovic (contact@markotrickovic.com)
 * @date:        11/06/2023 11:45 PM
 * @license:     MIT
 * @description: This header file contains the declarations of the data
 *               structures and functions related to trap handling in the x86_64
 *               architecture.
 *
 *               A trap is an exception or an interrupt that occurs during the
 *               execution of a program.
 *
 *                  - An exception is an unexpected event that is caused by the
 *                    program itself, such as division by zero or a page fault.
 *
 *                  - An interrupt is an external event that is triggered by a
 *                    device, such as a timer or a keyboard.
 *
 *               The header file includes a header file named stdint.h, which
 *               defines the standard integer types, such as uint16_t and
 *               uint64_t.
 *
 *               The header file defines a struct named IdtEntry, which is the
 *               structure of an interrupt descriptor table (IDT) entry.
 *
 *               The IDT is a data structure that maps each interrupt vector (a
 *               number from 0 to 255) to an interrupt handler function, which
 *               is executed when the corresponding interrupt occurs.
 *
 *                  - The IdtEntry struct contains the address and attributes of
 *                    the interrupt handler function.
 *
 *               The header file also defines a struct named IdtPtr, which is
 *               the structure of an interrupt descriptor table pointer.
 *
 *                  - The IdtPtr struct contains the base address and the size
 *                    of the IDT.
 *
 *                  - The IdtPtr struct has an attribute to prevent padding,
 *                    which means that the compiler will not add any extra bytes
 *                    between the fields of the struct.
 *
 *              The header file further defines a struct named TrapFrame, which
 *              is the structure of a trap frame.
 *
 *              A trap frame is a data struct that stores the state of the CPU
 *              registers when a trap occurs.
 *
 *              The TrapFrame struct contains the values of the general-purpose
 *              registers, such as RAX and RBX, as well as the values of the
 *              special registers, such as RIP and RFLAGS.
 *
 *              The header file declares the functions related to trap handling.
 *              Each function corresponds to an interrupt vector that handles a
 *              specific trap.
 *
 *              The functions are defined in trap.asm and trap.c.
 *
 * @note:      This code is part of the os-dev-udemy-wsl project, which is a
 *             course on operating system development using Windows Subsystem
 *             for Linux (WSL).
 *
 * Revision History:
 *
 *   - Revision 0.1: 11/06/2023 Marko Trickovic
 *     Initial version that declares data structures and functions for trap
 *     handling.
 *
 * Part of the os-dev-udemy-wsl.
 */

#ifndef _TRAP_H_
#define _TRAP_H_

#include "stdint.h"

// struct IdtEntry - The structure of an interrupt descriptor table entry
struct IdtEntry {
    uint16_t low;           // The lower 16 bits of the handler address
    uint16_t selector;      // The code segment selector
    uint8_t res0;           // Reserved, set to zero
    uint8_t attr;           // The type and attributes of the entry
    uint16_t mid;           // The middle 16 bits of the handler address
    uint32_t high;          // The higher 32 bits of the handler address
    uint32_t res1;          // Reserved, set to zero
};

// struct IdtPtr - The structure of an interrupt descriptor table pointer
struct IdtPtr {
    uint16_t limit;         // The size of the IDT in bytes
    uint64_t addr;          // The base address of the IDT
} __attribute__((packed));  // The attribute to prevent padding

/**
 * struct TrapFrame - The structure of a trap frame
 * A trap frame is a data structure that stores the state of the CPU registers
 * when a trap (an exception or an interrupt) occurs.
*/
struct TrapFrame {
    int64_t r15;
    int64_t r14;
    int64_t r13;
    int64_t r12;
    int64_t r11;
    int64_t r10;
    int64_t r9;
    int64_t r8;
    int64_t rbp;
    int64_t rdi;
    int64_t rsi;
    int64_t rdx;
    int64_t rcx;
    int64_t rbx;
    int64_t rax;
    int64_t trapno;
    int64_t errorcode;
    int64_t rip;
    int64_t cs;
    int64_t rflags;
    int64_t rsp;
    int64_t ss;
};

/**
 * The declarations of the functions related to trap handling.
 * Each function corresponds to an interrupt vector that handles a specific
 * trap. A trap is an exception or an interrupt that occurs during the
 * execution of the program.
 * The functions are defined in trap.asm and trap.c.
*/
void vector0(void);         // Handles divide by zero exception
void vector1(void);         // Handles debug exception
void vector2(void);         // Handles non-maskable interrupt
void vector3(void);         // Handles breakpoint exception
void vector4(void);         // Handles overflow exception
void vector5(void);         // Handles bound range exceeded exception
void vector6(void);         // Handles invalid opcode exception
void vector7(void);         // Handles device not available exception
void vector8(void);         // Handles double fault exception
void vector10(void);        // Handles invalid TSS exception
void vector11(void);        // Handles segment not present exception
void vector12(void);        // Handles stack-segment fault exception
void vector13(void);        // Handles general protection fault exception
void vector14(void);        // Handles page fault exception
void vector16(void);        // Handles x87 floating-point exception
void vector17(void);        // Handles alignment check exception
void vector18(void);        // Handles machine check exception
void vector19(void);        // Handles SIMD floating-point exception
void vector32(void);        // Handles timer interrupt
void vector39(void);        // Handles keyboard interrupt
void init_idt(void);        // Initializes the interrupt descriptor table
void eoi(void);             // Sends end of interrupt signal
void load_idt(struct IdtPtr *ptr);  // Loads the interrupt descriptor table ptr
unsigned char read_isr(void);       // Reads the interrupt service register

#endif
