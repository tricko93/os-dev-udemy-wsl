# Kernel makefile

# Include the global variables
include ../global.mak

# Define GCC flags
CFLAGS = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone

# Define all obj files
ALL_OBJS = kernel.o main.o

# Define the default target
.PHONY: all
all: $(ALL_OBJS) link

# Define a rule for assembling the kernel.asm that's bootstrapping C code
kernel.o: kernel.asm
	$(NASM) -f elf64 -lkernel.lst -o $@ $<

# Define a rule to compile all C code
%.o: %.c
	$(CC) $(CFLAGS) -c $<

# Define a rule for linking kernel
.PHONY: link
link:
	ld -nostdlib -T ../link.lds -o kernel $(ALL_OBJS)
	objcopy -O binary kernel kernel.bin
	rm kernel

# Define a rule for cleaning up the subdirectories
.PHONY: clean
clean:
	rm *.lst *.bin *.o
