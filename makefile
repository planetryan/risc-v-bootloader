TARGET := riscv64gc-unknown-none-elf
TOOLCHAIN_PREFIX := riscv64-unknown-none-elf
CC := $(TOOLCHAIN_PREFIX)-gcc
AS := $(TOOLCHAIN_PREFIX)-as
LD := $(TOOLCHAIN_PREFIX)-ld
BUILD_DIR := target/$(TARGET)/release
ASM_SOURCES := start.S
RUST_SOURCES := src/lib.rs
ASM_OBJECTS := $(ASM_SOURCES:.S=.o)
RUST_OBJECTS := $(BUILD_DIR)/bootloader # Changed from libbootloader.a
EXECUTABLE := $(BUILD_DIR)/bootloader.elf
LINKER_SCRIPT := link.lda
CFLAGS := -Wall -Wextra -O2 -march=rv64gc
ASFLAGS :=
LDFLAGS := -T $(LINKER_SCRIPT) --gc-sections -static # Added -static
CARGO_BUILD := cargo build --target $(TARGET) --release
all: $(EXECUTABLE)
$(EXECUTABLE): $(ASM_OBJECTS) $(RUST_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^
start.o: start.S
	$(AS) $(ASFLAGS) -o $@ $<
$(BUILD_DIR)/bootloader: $(RUST_SOURCES) # Changed from libbootloader.a
	$(CARGO_BUILD)
clean:
	rm -rf $(BUILD_DIR) *.o $(EXECUTABLE)