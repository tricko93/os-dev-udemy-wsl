;------------------------------------------------------------------------------
; @file:        loader.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/24/2023 10:00 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This program is responsible for the next steps after the boot
;               sector program.
;
;               It performs the following steps:
;
;                   1. Prints a success message on the console.
;
;                   2. Halts the processor in an infinite loop.
;
; Revision History:
;
; Revision 0.1: 10/24/2023 Marko Trickovic
; Initial creation of the loader assembly program.
; Added functionality to print a success message on the console.
; Implemented an infinite loop at the end of the program to keep the system
; in a stable state after the loading process is complete.
;------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7e00]        ; Set origin to boot sector address


start:
    mov ah,0x13         ; Write String function
    mov al,1            ; String with color
    mov bx,0xa          ; Light green on black
    xor dx,dx           ; Row 0, column 0
    mov bp,Message      ; Message address
    mov cx,MessageLen   ; Length of the string
    int 0x10            ; Call BIOS interrupt 0x10

End:
    hlt             ; Halt the processor, waiting for the next interrupt
    jmp End         ; Jump back to 'End', creating an infinite loop

Message:    db "loader starts"  ; Define a byte array 'Message'
MessageLen: equ $-Message   ; Length of 'Message' by '$' minus start address
