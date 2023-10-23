; ------------------------------------------------------------------------------
; @file:        boot.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/23/2023 08:00 PM
; @license:     MIT
; @language:    Assembly
; @platform:    x86_64
; @description: This program is the first code that runs when the computer
;               starts up.
;
;               It performs the following steps:
;
;                   1. Clears the segment registers and sets the stack pointer.
;
;                   2. The program prints a message on the console.
;
;                   3. The program halts the processor in an infinite loop.
;
; Revision History:
;
; Revision 0.1: 10/23/2023 Marko Trickovic
; Initial version that prints a message and halts the processor.
; ------------------------------------------------------------------------------

[BITS 16]           ; We are using 16-bit architecture
[ORG 0x7c00]        ; This is the memory location where BIOS loads the boot
                    ; sector

start:
    xor ax,ax       ; Zero out segment registers to ensure they are clean
    mov ds,ax       ; before use
    mov es,ax  
    mov ss,ax
    mov sp,0x7c00   ; Set stack pointer to 0x7c00 in boot sector code

; Function: PrintMessage
PrintMessage:
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

Message:    db "Hello"      ; Define a byte array 'Message'
MessageLen: equ $-Message   ; Calculate the length of 'Message' by subtracting
                            ; its starting address from the current address
                            ; ('$')

; Master Boot Record (MBR) Partition Table
; Partition Entry Structure:
times (0x1be-($-$$)) db 0

    db 80h                  ; Byte 0: Boot Indicator
    db 0,2,0                ; Bytes 1-3: CHS address of 1st abs. sect.
    db 0f0h                 ; Byte 4: Partition type
    db 0ffh,0ffh,0ffh       ; Byte 5-7: CHS address of last abs. sect.
    dd 1                    ; Byte 8-11: LBA (first abs. sector in the part.)
    dd (20*16*63-1)         ; Bytes 12-15: Number of sectors in the partition
	
    times (16*3) db 0       ; This will zero out the last 3 partition entries.

    db 0x55                 ; The magic signature (0x55AA) at the end of the
    db 0xaa                 ; boot sector.

