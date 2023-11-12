;------------------------------------------------------------------------------
; @file:        boot.asm
; @author:      Marko Trickovic (contact@markotrickovic.com)
; @date:        11/12/2023 10:34 PM
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
;   - Revision 0.1: 10/23/2023 Marko Trickovic
;     Initial version that prints a message and halts the processor.
;
;   - Revision 0.2: 10/24/2023  Marko Trickovic
;     Added TestDiskExtension routine to boot sector code.
;
;   - Revision 0.3: 10/24/2023  Marko Trickovic
;     Added new feature to read the loader program from the disk.
;     Implemented error handling to print an error message if there's an error
;     during the read operation.
;     If there's no error, the program now jumps to the loaded code.
;
;   - Revision 0.4: 11/12/2023 Marko Trickovic
;     Refactored the comments to improve readability.
; ------------------------------------------------------------------------------

[BITS 16]           ; Use 16-bit mode
[ORG 0x7c00]        ; Set origin to boot sector address

; @routine:          start
; @brief:            The entry point of the program, which sets up the registers
;                    and the stack for the execution of the main program.
;
; @param:      ax    The register that is used to clear and set the segment
;                    registers.
; @param:      ds    The data segment register that is used to access the data
;                    segment.
; @param:      es    The extra segment register that is used to access the extra
;                    segment.
; @param:      ss    The stack segment register that is used to access the stack
;                    segment.
; @param:      sp    The stack pointer register that is used to access the top
;                    of the stack.
;
; @return:           None, as this routine does not return any value, but jumps
;                    to the main routine, which is the main function of the
;                    program.
;
start:
    xor ax,ax       ; Clear ax register
    mov ds,ax       ; Set data segment to 0
    mov es,ax       ; Set extra segment to 0
    mov ss,ax       ; Set stack segment to 0
    mov sp,0x7c00   ; Set stack pointer to boot sector address
;
; @routine:           TestDiskExtension
; @brief:             A routine to test if the disk supports extended functions.
;
; @param:       dl    The drive ID to test. This parameter is passed in the dl
;                     register.
; @param:       ah    The BIOS code to test disk extensions. This parameter is
;                     set to 0x41 by the routine.
; @param:       bx    A code to check disk function support. This parameter is
;                     set to 0x55aa by the routine.
;
; @return:            The zero flag (ZF) is set to 1 if the disk supports
;                     extended functions, or 0 if not. The routine also sets the
;                     carry flag (CF) to 1 if there is an error, or 0 if not.
;
TestDiskExtension:
    mov [DriveId],dl    ; Store the drive ID in memory
    mov ah,0x41         ; BIOS code to test disk extensions
    mov bx,0x55aa       ; A code to check disk function support
    int 0x13            ; Call BIOS interrupt 13
    jc NotSupport       ; Jump if error
    cmp bx,0xaa55       ; Verify if extended disk functions are supported
    jne NotSupport      ; Jump if no disk functions

; @routine:           LoadLoader
; @brief:             A routine to load a loader program from the disk into
;                     memory and jump to it.
;
; @param:       si    The address of the ReadPacket structure that contains the
;                     information for the read operation. This parameter is
;                     passed in the si register.
; @param:       dl    The drive number from which to read the loader program.
;                     This parameter is passed in the dl register, and it is
;                     also stored in the DriveId variable in memory.
; @param:       ah    The BIOS code to read sectors from the disk into memory.
;                     This parameter is set to 0x42 by the routine.
;
; @return:            The routine does not return any value, as it jumps to the
;                     loaded code at the memory address 0x7e00. The routine also
;                     sets the carry flag (CF) to 1 if there is an error during
;                     the read operation, or 0 if not.
;
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

; @routine:           ReadError
; @brief:             A routine to print an error message on the screen and halt
;                     the processor.
;
; @param:       ah    The BIOS code to write a string on the screen. This
;                     parameter is set to 0x13 by the routine.
; @param:       al    The mode of the string writing operation. This parameter
;                     is set to 1 by the routine, which means the string has
;                     color attributes.
; @param:       bx    The color attributes of the string. This parameter is set
;                     to 0xa by the routine, which means light green on black.
; @param:       dx    The row and column coordinates of the string. This
;                     parameter is set to 0 by the routine, which means row 0
;                     and column 0.
; @param:       bp    The address of the string to be written. This parameter is
;                     set to Message by the routine, which is a variable that
;                     contains the error message.
; @param:       cx    The length of the string to be written. This parameter is
;                     set to MessageLen by the routine, which is a variable that
;                     contains the length of the error message.
;
; @return:            The routine does not return any value, as it halts the
;                     processor in an infinite loop after printing the error
;                     message.
;
ReadError:

; @label:       NotSupport
; @brief:       Handles the error case when the processor does not support disk
;               extension.
;
; @return:      None. This label does not return any value.
;
NotSupport:
    mov ah,0x13         ; Write String function
    mov al,1            ; String with color
    mov bx,0xa          ; Light green on black
    xor dx,dx           ; Row 0, column 0
    mov bp,Message      ; Message address
    mov cx,MessageLen   ; Length of the string
    int 0x10            ; Call BIOS interrupt 0x10

; @label:       End
; @brief:       Halts the CPU and creates an infinite loop.
;
; @return:      None. This label does not return any value.
;
End:
    hlt             ; Halt the processor, waiting for the next interrupt
    jmp End         ; Jump back to 'End', creating an infinite loop

; @var:         DriveId
;
; @brief:       A byte variable that stores the drive ID from which the program
;               was loaded.
;
DriveId:    db 0                                    ; Byte for DriveId

; @var:         Message
;
; @brief:       A byte array that contains the error message to be displayed on
;               the screen.
;
Message:    db "We have an error in boot process"   ; Define a byte array

; @var:         MessageLen
;
; @brief:       A constant that holds the length of the Message array.
;
MessageLen: equ $-Message                           ; Length of 'Message'

; @var:         ReadPacket
;
; @brief:       A 16-byte structure that contains the parameters for the disk
;               read operation in extended mode.
;
ReadPacket: times 16 db 0                           ; Reserve a block of memory

; @var:         MBR
;
; @brief:       A 64-byte structure that contains the Master Boot Record (MBR)
;               partition table.
;
; @details:     The MBR partition table consists of four 16-byte entries, each
;               describing a primary partition on the disk. Each entry has the
;               following fields:
;                   - Boot Indicator: A byte that indicates if the partition is
;                     bootable or not (80h for bootable, 00h for non-bootable).
;                   - CHS address of first sector: Three bytes that specify the
;                     Cylinder-Head-Sector address of the first sector in the
;                     partition.
;                   - Partition type: A byte that identifies the type of the
;                     partition (e.g., 0f0h for FAT32, 07h for NTFS, etc.).
;                   - CHS address of last sector: Three bytes that specify the
;                     Cylinder-Head-Sector address of the last sector in the
;                     partition.
;                   - LBA of first sector: Four bytes that specify the Logical
;                     Block Address of the first sector in the partition.
;                   - Number of sectors in partition: Four bytes that specify
;                     the number of sectors in the partition.
;
times (0x1be-($-$$)) db 0

    db 80h                  ; Boot Indicator (byte 0)
    db 0,2,0                ; CHS address of first sector (bytes 1-3)
    db 0f0h                 ; Partition type (byte 4)
    db 0ffh,0ffh,0ffh       ; CHS address of last sector (bytes 5-7)
    dd 1                    ; LBA of first sector (bytes 8-11)
    dd (20*16*63-1)         ; Number of sectors in partition (bytes 12-15)
	
    times (16*3) db 0       ; Zero out the last 3 partition entries

    db 0x55                 ; Magic signature (0x55AA) for boot sector
    db 0xaa
