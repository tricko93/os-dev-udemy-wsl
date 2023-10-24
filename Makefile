# Top-level makefile

# Include the global variables
include global.mak

# Define the subdirectories that contain the sub-makefiles
SUBDIRS = boot

# Define the default target
.PHONY: all $(SUBDIRS)
all: $(SUBDIRS) boot.img

# Define a rule for each subdirectory
$(SUBDIRS):
	$(MAKE) -s -C $@

# Define a rule to create hard disk image
boot.img: .FORCE
	dd if=boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=boot/loader.bin of=$@ bs=512 count=5 seek=1 conv=notrunc

.PHONY: .FORCE
.FORCE: ;

# Define a rule for cleaning up the subdirectories
.PHONY: clean
clean:
	for dir in $(SUBDIRS); do \
        $(MAKE) -C $$dir clean; \
    done

