CROSS = riscv64-unknown-elf-

OBJS = start.o # Removed entry.o

TARGET = bootloader.elf
BIN = bootloader.bin

ASFLAGS = -march=rv64im -mabi=lp64 -Wall
RUSTFLAGS = --target=riscv64gc-unknown-none-elf
LDFLAGS = -T link.lda

BUILD_DIR = target/riscv64gc-unknown-none-elf/release

QEMU_FLAGS = -machine virt -nographic -bios none -display sdl

# Main target to build the bootloader ELF
all: $(BUILD_DIR)/$(TARGET)

# Assembly files
start.o: start.S
	$(CROSS)as $(ASFLAGS) -o $@ $<

# Build the Rust static library
$(BUILD_DIR)/libbootloader.a: src/lib.rs
	cargo clean
	cargo build --target=riscv64gc-unknown-none-elf --release --no-default-features -v
	# Check if cargo build was successful
	if [ $$? -eq 0 ]; then \
		echo "Cargo build successful"; \
	else \
		echo "Error: Cargo build failed"; \
		exit 1; \
	fi

# Link all the object files and the Rust static library into the bootloader ELF
$(BUILD_DIR)/$(TARGET): $(OBJS) $(BUILD_DIR)/libbootloader.a
	@mkdir -p $(BUILD_DIR)
	$(CROSS)ld $(LDFLAGS) -o $@ $(OBJS) $(BUILD_DIR)/libbootloader.a

# Convert the ELF file to a binary
bin: $(BUILD_DIR)/$(TARGET)
	$(CROSS)objcopy -O binary $< $(BIN)

# Run QEMU with the ELF file
run: all
	qemu-system-riscv64 $(QEMU_FLAGS) -kernel $(BUILD_DIR)/$(TARGET)

run-bios: bin
	qemu-system-riscv64 $(QEMU_FLAGS) -bios $(BIN)

start.o: start.S
	$(CROSS)as $(ASFLAGS) -o $@ $<
	echo "start.o created in $(shell pwd)"

clean:
	rm -f *.o *.bin
	rm -f $(BUILD_DIR)/$(TARGET)
	rm -rf $(BUILD_DIR)/deps/
	rm -f $(BUILD_DIR)/libbootloader.a

	