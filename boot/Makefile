# Bootloader makefile

# Include the global variables
include ../global.mak

# Define the default target
.PHONY: all
all: boot.bin loader.bin

# Define a rule for assembling assembly programs into binary executables
%.bin: %.asm
	$(NASM) $< -l$*.lst -o$@

# Define a rule for cleaning up the subdirectories
.PHONY: clean
clean:
	rm *.lst *.bin
