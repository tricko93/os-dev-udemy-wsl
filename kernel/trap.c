/******************************************************************************
 * @file         trap.c
 * @author       Marko Trickovic (contact@markotrickovic.com)
 * @date         11/06/2023 11:45 PM
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
 * Revision 0.1: 11/06/2023 Marko Trickovic
 * Initial version that declares data structures and functions for trap
 * handling.
 *
 * Part of the os-dev-udemy-wsl.
 *****************************************************************************/

#include "trap.h"

/**
 * Define static global idt_pointer variable and static global IdtEntry array.
 * 
 * static - the definitions are only visible in this file.
 */
static struct IdtPtr idt_pointer;
static struct IdtEntry vectors[256];

/**
 * init_idt_entry - a static function that initializes an interrupt descriptor
 * table entry
 * 
 * @param IdtEntry entry: a pointer to the entry to be initialized
 * @param uint64_t addr: the address of the interrupt handler function
 * @param uint8_t attribute: the type and attributes of the entry
 * 
 * @return void
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
 * init_idt - a function that initializes the interrupt descriptor table
 * 
 * It sets up the entries for each interrupt vector using the init_idt_entry
 * function.
 * 
 * It also sets up the pointer to the interrupt descriptor table using the
 * idt_pointer struct.
 * 
 * It then loads the pointer to the interrupt descriptor table using the
 * load_idt function.
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
 * handler - A function that handles traps
 * 
 * This function checks the trap number and performs different actions
 * accordingly.
 * 
 * For timer interrupt (trap number 32), it sends an end of interrupt signal.
 * For keyboard interrupt (trap number 39), it reads the interrupt service
 * register and sends an end of interrupt signal only if the highest bit is
 * set.
 * For other traps, it enters an infinite loop.
 * 
 * @param TrapFrame *tf: a pointer to the trap frame that contains the state
 * of the CPU registers when the trap occurred
 * 
 * @return void
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
