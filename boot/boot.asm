;------------------------------------------------------------------------------
; @file:        boot.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        10/24/2023 10:00 PM
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
;                   2. Test disk extensions using the TestDiskExtension
;                      function.
;
;                   3. Loads the loader program from the disk into memory using
;                      a BIOS interrupt routine.
;
;                   4. Jumps to the start of the loader program.
;
;                   5. The loader program prints a message on the console.
;
;                   6. The loader program halts the processor in an infinite
;                      loop.
;
; Usage: make
;
; Revision History:
;
; Revision 0.1: 10/23/2023 Marko Trickovic
; Initial version that prints a message and halts the processor.
;
; Revision 0.2  10/24/2023  Marko Trickovic
; Added TestDiskExtension routine to boot sector code
;
; Revision 0.3  10/24/2023  Marko Trickovic
; Added new feature to read the loader program from the disk.
;
; - Implemented error handling to print an error message if there's an error
;   during the read operation.
;
; - If there's no error, the program now jumps to the loaded code.
;------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7c00]        ; Set origin to boot sector address

start:
    xor ax,ax       ; Clear ax register
    mov ds,ax       ; Set data segment to 0
    mov es,ax       ; Set extra segment to 0
    mov ss,ax       ; Set stack segment to 0
    mov sp,0x7c00   ; Set stack pointer to boot sector address

; Function: TestDiskExtension
TestDiskExtension:
    mov [DriveId],dl    ; Store the drive ID in memory
    mov ah,0x41         ; BIOS code to test disk extensions
    mov bx,0x55aa       ; A code to check disk function support
    int 0x13            ; Call BIOS interrupt 13
    jc NotSupport       ; Jump if error
    cmp bx,0xaa55       ; Verify if extended disk functions are supported
    jne NotSupport      ; Jump if no disk functions

; Function: LoadLoader
LoadLoader:
    mov si,ReadPacket       ; Set SI to the address of ReadPacket
    mov word[si],0x10       ; Set the size of the ReadPacket structure to 16 B
    mov word[si+2],5        ; Set the number of sectors to read to 5
    mov word[si+4],0x7e00   ; Set the memory address where to read data
    mov word[si+6],0        ; Set the segment offset to 0
    mov dword[si+8],1       ; Address low
    mov dword[si+0xc],0     ; Address high
    mov dl,[DriveId]        ; Set the drive number from which to read
    mov ah,0x42             ; Read sectors from the disk into memory
    int 0x13                ; Call BIOS interrupt 0x13
    jc ReadError            ; Jump if error
    mov dl,[DriveId]        ; Set the drive number again
    jmp 0x7e00              ; Jump to the loaded code

; Function: ReadError
ReadError:
NotSupport:
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

DriveId:    db 0                ; Byte for DriveId
Message:    db "We have an error in boot process"   ; Define a byte array
MessageLen: equ $-Message   ; Length of 'Message' by '$' minus start address
ReadPacket: times 16 db 0   ; Reserve a block of memory used to store read data

; Master Boot Record (MBR) Partition Table
; Partition Entry Structure:
times (0x1be-($-$$)) db 0

    db 80h                  ; Boot Indicator (byte 0)
    db 0,2,0                ; CHS address of first sector (bytes 1-3)
    db 0f0h                 ; Partition type (byte 4)
    db 0ffh,0ffh,0ffh       ; CHS address of last sector (bytes 5-7)
    dd 1                    ; LBA of first sector (bytes 8-11)
    dd (20*16*63-1)         ; Number of sectors in partition (bytes 12-15)
	
    times (16*3) db 0       ; Zero out the last 3 partition entries.

    db 0x55                 ; Magic signature (0x55AA) for boot sector
    db 0xaa
