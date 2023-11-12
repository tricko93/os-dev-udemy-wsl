/* -----------------------------------------------------------------------------
 * @file:        trap.h
 * @author:      Marko Trickovic (contact@markotrickovic.com)
 * @date:        11/12/2023 10:34 PM
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
 *   - Revision 0.2: 11/12/2023 Marko Trickovic
 *     Refactored the comments to improve readability.
 *
 * Part of the os-dev-udemy-wsl.
 */

#ifndef _TRAP_H_
#define _TRAP_H_

#include "stdint.h"

/**
 * @brief:                The structure of an interrupt descriptor table entry.
 *
 * @struct:               IdtEntry
 *
 * @param[in]: low       The lower 16 bits of the handler address
 * @param[in]: selector  The code segment selector
 * @param[in]: res0      Reserved, set to zero
 * @param[in]: attr      The type and attributes of the entry
 * @param[in]: mid       The middle 16 bits of the handler address
 * @param[in]: high      The higher 32 bits of the handler address
 * @param[in]: res1      Reserved, set to zero
 */
struct IdtEntry {
    uint16_t low;
    uint16_t selector;
    uint8_t res0;
    uint8_t attr;
    uint16_t mid;
    uint32_t high;
    uint32_t res1;
};


/**
 * @brief:             The structure of an interrupt descriptor table pointer.
 *
 * @struct:            IdtPtr
 *
 * @param[in]: limit  The size of the IDT in bytes
 * @param[in]: addr   The base address of the IDT
 *
 * @return:            None
 *
 * @description:       This struct holds the base address and the size of the
 *                     IDT, which is a data structure that maps each interrupt
 *                     vector to an interrupt handler function. The struct has
 *                     an attribute to prevent padding, which means that the
 *                     compiler will not add any extra bytes between the fields
 *                     of the struct. This is necessary to ensure that the CPU
 *                     can access the IDT correctly.
 */
struct IdtPtr {
    uint16_t limit;
    uint64_t addr;
} __attribute__((packed));

/**
 * @brief:                 The structure of a trap frame.
 *
 * @struct:                TrapFrame
 *
 * @description:           This struct contains the registers and flags that are
 *                         saved and restored during a trap, which is an
 *                         exception or an interrupt that occurs during the
 *                         execution of a program. The struct is pushed onto the
 *                         stack by the CPU when a trap occurs, and popped from
 *                         the stack by the handler function when the trap is
 *                         handled. The struct allows the handler function to
 *                         access and modify the state of the program before and
 *                         after the trap.
 *
 * @param:     r15         General purpose register 15
 * @param:     r14         General purpose register 14
 * @param:     r13         General purpose register 13
 * @param:     r12         General purpose register 12
 * @param:     r11         General purpose register 11
 * @param:     r10         General purpose register 10
 * @param:     r9          General purpose register 9
 * @param:     r8          General purpose register 8
 * @param:     rbp         Base pointer register
 * @param:     rdi         Destination index register
 * @param:     rsi         Source index register
 * @param:     rdx         Data register
 * @param:     rcx         Counter register
 * @param:     rbx         Base register
 * @param:     rax         Accumulator register
 * @param:     trapno      Trap number
 * @param:     errorcode   Error code
 * @param:     rip         Instruction pointer register
 * @param:     cs          Code segment register
 * @param:     rflags      Flags register
 * @param:     rsp         Stack pointer register
 * @param:     ss          Stack segment
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
 * @defgroup:  vector Vector functions
 * @name:      vector
 * @brief:     This group contains the functions that handle various exceptions
 *             and interrupts. @{
 */
/**
 * @fn:        vector0(void)
 *
 * @brief:     Handles divide by zero exception.
 */
void vector0(void);
/**
 * @fn:        vector1(void)
 *
 * @brief:     Handles debug exception.
 */
void vector1(void);
/**
 * @fn:        vector2(void)
 *
 * @brief:     Handles non-maskable interrupt.
 */
void vector2(void);
/**
 * @fn:        vector3(void)
 *
 * @brief:     Handles breakpoint exception.
 */
void vector3(void);
/**
 * @fn:        vector4(void)
 *
 * @brief:     Handles overflow exception.
 */
void vector4(void);
/**
 * @fn:        vector5(void)
 *
 * @brief:     Handles bound range exceeded exception.
 */
void vector5(void);
/**
 * @fn:        vector6(void)
 *
 * @brief:     Handles invalid opcode exception.
 */
void vector6(void);
/**
 * @fn:        vector7(void)
 *
 * @brief:     Handles device not available exception.
 */
void vector7(void);
/**
 * @fn:        vector8(void)
 *
 * @brief:     Handles double fault exception.
 */
void vector8(void);
/**
 * @fn:        vector10(void)
 *
 * @brief:     Handles invalid TSS exception.
 */
void vector10(void);
/**
 * @fn:        vector11(void)
 *
 * @brief:     Handles segment not present exception.
 */
void vector11(void);
/**
 * @fn:        vector12(void)
 *
 * @brief:     Handles stack-segment fault exception.
 */
void vector12(void);
/**
 * @fn:        vector13(void)
 *
 * @brief:     Handles general protection fault exception.
 */
void vector13(void);
/**
 * @fn:        vector14(void)
 *
 * @brief:     Handles page fault exception.
 */
void vector14(void);
/**
 * @fn:        vector16(void)
 *
 * @brief:     Handles x87 floating-point exception.
 */
void vector16(void);
/**
 * @fn:        vector17(void)
 *
 * @brief:     Handles alignment check exception.
 */
void vector17(void);
/**
 * @fn:        vector18(void)
 *
 * @brief:     Handles machine check exception.
 */
void vector18(void);
/**
 * @fn:        vector19(void)
 *
 * @brief:     Handles SIMD floating-point exception.
 */
void vector19(void);
/**
 * @fn:        vector32(void)
 *
 * @brief:     Handles timer interrupt.
 */
void vector32(void);
/**
 * @fn:        vector39(void)
 *
 * @brief:     Handles keyboard interrupt.
 */
void vector39(void);
/**
 * @fn:        init_idt(void)
 *
 * @brief:     Initializes the interrupt descriptor table.
 */
void init_idt(void);
/**
 * @fn:        eoi(void)
 *
 * @brief:     Sends end of interrupt signal.
 */
void eoi(void);
/**
 * @fn:        load_idt(void)
 *
 * @brief:     Loads the interrupt descriptor table pointer.
 *
 * @param:     ptr   The pointer
 */
void load_idt(struct IdtPtr *ptr);
/**
 * @fn:        read_isr(void)
 *
 * @brief:     Reads the interrupt service register.
 *
 * @return:    Returns an 8 bits value indicating the state of different
 *             interrupt sources.
 */
unsigned char read_isr(void);
/**
 * @}
 */

#endif
