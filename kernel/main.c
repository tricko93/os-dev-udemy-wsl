/******************************************************************************
 * @file:        main.c
 * @author:      Marko Trickovic (contact@markotrickovic.com)
 * @date:        11/12/2023 10:34 PM
 * @license:     MIT
 * @language:    C
 * @platform:    x86_64
 * @description: This file contains the KMain function that is invoked to do
 *               the system initialization of components, such as the interrupt
 *               descriptor table, the console, the timer, and the keyboard.
 *
 * Revision History:
 *
 *   - Revision 0.1: 11/06/2023 Marko Trickovic
 *     Initial version that prints a character.
 *
 *   - Revision 0.2: 11/06/2023 Marko Trickovic
 *     Implement trap handling. Test the trap handling in KMain.
 *
 *   - Revision 0.3: 11/12/2023 Marko Trickovic
 *     Refactored the comments to improve readability.
 *
 * Part of the os-dev-udemy-wsl.
 *****************************************************************************/

#include "trap.h"

/**
 * @brief:          The main function of the kernel.
 *
 * @param:          None
 *
 * @return:         None
 *
 * @description:    This function is the entry point of the kernel, which is the
 *                  core component of the operating system. The function calls
 *                  the init_idt function to initialize the interrupt descriptor
 *                  table, which is a data structure that maps each interrupt
 *                  vector to an interrupt handler function. The function then
 *                  enters an infinite loop, waiting for interrupts to occur and
 *                  handle them accordingly.
 */
void KMain(void)
{
    init_idt();
}
