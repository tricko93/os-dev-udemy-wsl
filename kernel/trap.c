/******************************************************************************
 * @file         trap.c
 * @author       Marko Trickovic (contact@markotrickovic.com)
 * @date         11/12/2023 10:34 PM
 * @license      MIT
 * @description: This file contains the definitions and functions for setting up
 *               the interrupt descriptor table (IDT) in the x86_64
 *               architecture.
 *
 *               The IDT is a data structure that maps each interrupt vector (a
 *               number from 0 to 255) to an interrupt handler function, which
 *               is executed when the corresponding interrupt occurs.
 *
 *               The IDT is composed of 256 entries, each of which is a 16-byte
 *               struct called IdtEntry. The IdtEntry struct contains the
 *               address and attributes of the interrupt handler function.
 *
 *               The IDT is accessed by the CPU through a 10-byte struct called
 *               IdtPtr, which contains the base address and the size of the
 *               IDT.
 * 
 *               The file defines an external variable named handler, which is a
 *               pointer to a function that takes an int parameter and returns
 *               void. This function is used as the default interrupt handler
 *               for all vectors.
 *
 *               The file also defines two global variables named read_isr and
 *               load_idt, which are pointers to functions that read the
 *               interrupt service routine (ISR) number from the interrupt
 *               controller and load the IDT pointer to the CPU, respectively.
 *
 *               The file includes a header file named trap.h, which contains
 *               the declarations of the IdtEntry and IdtPtr structs, as well as
 *               the prototypes of the handler, read_isr, and load_idt
 *               functions.
 *
 *               The file defines a static function named init_idt_entry, which
 *               initializes an IDT entry with the given address and attribute.
 *
 *               The file defines a function named init_idt, which initializes
 *               the IDT with the default handler for each vector, sets up the
 *               IDT pointer, and loads the IDT to the CPU.
 *
 *               The file defines a function named handler, which handles traps.
 *
 *               A trap is an exception or an interrupt that occurs during the
 *               execution of a program. An exception is an unexpected event
 *               that is caused by the program itself, such as a division by
 *               zero or a page fault. An interrupt is an external event that is
 *               triggered by a device, such as a timer or a keyboard.
 *
 *               When a trap occurs, the CPU saves the state of the registers in
 *               a struct called TrapFrame, and then jumps to the corresponding
 *               interrupt handler function, which is specified by the IDT entry
 *               for the trap number.
 *
 *               The handler function takes a pointer to the TrapFrame as a
 *               parameter, and checks the trap number to perform different
 *               actions accordingly.
 * 
 *               For the timer interrupt (trap number 32), the handler function
 *               sends end of interrupt (EOI) signal to the interrupt
 *               controller, which is a device that manages the interrupts and
 *               signals the CPU when an interrupts occurs.
 *
 *               For the keyboard interrupt (trap number 39), the handler
 *               function reads the interrupt service register (ISR) from the
 *               interrupt controller, which is a byte that indicates which keys
 *               are pressed on the keyboard. The handler function sends an EOI
 *               signal only if the highest bit of the ISR is set, which means
 *               that a key has been released.
 *
 *               For other traps, the handler function enters an infinite loop,
 *               which means that the program is halted and cannot resume. This
 *               is a simple way of handling exceptions that are not expected or
 *               handled by the program.
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
 *****************************************************************************/

#include "trap.h"

/**
 * @brief:       A pointer to the interrupt descriptor table (IDT).
 *
 * @type:        struct IdtPtr
 * @size:        6 bytes
 * @description: This variable holds the base address and the size of the IDT,
 *               which is a data structure that maps each interrupt vector to an
 *               interrupt handler function.
 */
static struct IdtPtr idt_pointer;

/**
 * @brief:       An array of interrupt descriptor table entries.
 *
 * @type:        struct IdtEntry
 * @size:        256 * 16 bytes
 * @description: This variable contains 256 elements, each of which is a struct
 *               that represents an IDT entry. An IDT entry contains the address
 *               and attributes of an interrupt handler function, which is
 *               executed when the corresponding interrupt occurs.
 */
static struct IdtEntry vectors[256];

/**
 * @brief:     Initializes the idt entry.
 *
 * @param:     entry      a pointer to the entry to be initialized
 * @param[in]: addr       the address of the interrupt handler function
 * @param[in]: attribute  the type and attributes of the entry
 * 
 * @return:    None
 */
static void init_idt_entry(struct IdtEntry *entry, uint64_t addr, uint8_t attribute)
{
    entry->low = (uint16_t)addr;
    entry->selector = 8;
    entry->attr = attribute;
    entry->mid = (uint16_t)(addr>>16);
    entry->high = (uint32_t)(addr>>32);
}

/**
 * @brief:          A function that initializes the interrupt descriptor table
 *                  (IDT).
 * 
 * @param:          None
 * 
 * @return:         None
 * 
 * @description:    This function initializes the IDT by calling the
 *                  init_idt_entry function for each interrupt vector and
 *                  setting the corresponding interrupt handler function, type,
 *                  and attributes.
 *
 *                  The function also sets the IDT pointer to point to the base
 *                  address and the size of the IDT, and loads the IDT into the
 *                  CPU using the load_idt function.
 */
void init_idt(void)
{
    init_idt_entry(&vectors[0],(uint64_t)vector0,0x8e);
    init_idt_entry(&vectors[1],(uint64_t)vector1,0x8e);
    init_idt_entry(&vectors[2],(uint64_t)vector2,0x8e);
    init_idt_entry(&vectors[3],(uint64_t)vector3,0x8e);
    init_idt_entry(&vectors[4],(uint64_t)vector4,0x8e);
    init_idt_entry(&vectors[5],(uint64_t)vector5,0x8e);
    init_idt_entry(&vectors[6],(uint64_t)vector6,0x8e);
    init_idt_entry(&vectors[7],(uint64_t)vector7,0x8e);
    init_idt_entry(&vectors[8],(uint64_t)vector8,0x8e);
    init_idt_entry(&vectors[10],(uint64_t)vector10,0x8e);
    init_idt_entry(&vectors[11],(uint64_t)vector11,0x8e);
    init_idt_entry(&vectors[12],(uint64_t)vector12,0x8e);
    init_idt_entry(&vectors[13],(uint64_t)vector13,0x8e);
    init_idt_entry(&vectors[14],(uint64_t)vector14,0x8e);
    init_idt_entry(&vectors[16],(uint64_t)vector16,0x8e);
    init_idt_entry(&vectors[17],(uint64_t)vector17,0x8e);
    init_idt_entry(&vectors[18],(uint64_t)vector18,0x8e);
    init_idt_entry(&vectors[19],(uint64_t)vector19,0x8e);
    init_idt_entry(&vectors[32],(uint64_t)vector32,0x8e);
    init_idt_entry(&vectors[39],(uint64_t)vector39,0x8e);

    idt_pointer.limit = sizeof(vectors)-1;
    idt_pointer.addr = (uint64_t)vectors;
    load_idt(&idt_pointer);
}

/**
 * @brief:      A function that handles the traps that occur during the
 *              execution of the program.
 *
 * @param[in]:  struct TrapFrame *tf  a pointer to the trap frame, which
 *                                    contains the registers and flags that are
 *                                    saved and restored during a trap.
 *
 * @return:      None
 *
 * @description: This function handles the traps according to the trap number,
 *               which is stored in the trap frame.
 *               The function uses the eoi and read_isr functions to send an
 *               end-of-interrupt signal and read the in-service register value,
 *               respectively.
 *               The function handles two specific cases: when the trap number
 *               is 32, which means a timer interrupt, and when the trap number
 *               is 39, which means a spurious interrupt. For other cases, the
 *               function enters an infinite loop.
 */
void handler(struct TrapFrame *tf)
{
    unsigned char isr_value;

    switch (tf->trapno) {
        case 32:
            eoi();
            break;

        case 39:
            isr_value = read_isr();
            if ((isr_value&(1<<7)) != 0) {
                eoi();
            }
            break;

        default:
            while (1) { }
    }
}
