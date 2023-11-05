/******************************************************************************
 * @file:        main.c
 * @author:      Marko Trickovic (contact@markotrickovic.com)
 * @date:        11/06/2023 08:55 PM
 * @license:     MIT
 * @language:    C
 * @platform:    x86_64
 * @description: This file contains the KMain function that initializes the
 *               system, prints a character on the screen as a test that C code
 *               is bootstrapped.
 *
 * Revision 0.1: 11/06/2023 Marko Trickovic
 * Initial version that prints a character.
 *****************************************************************************/

void KMain(void)
{
    char* p = (char*)0xb8000;

    p[0] = 'C';
    p[1] = 0xa;
}
