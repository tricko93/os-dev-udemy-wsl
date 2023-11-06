/******************************************************************************
 * @file:        main.c
 * @author:      Marko Trickovic (contact@markotrickovic.com)
 * @date:        11/06/2023 08:55 PM
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
 * Part of the os-dev-udemy-wsl.
 *****************************************************************************/

#include "trap.h"

void KMain(void)
{
    init_idt();
}
