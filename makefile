CROSS = riscv64-unknown-elf-

OBJS = start.o $(BUILD_DIR)/bootloader.o boot.o
TARGET = bootloader.elf
BIN = bootloader.bin

ASFLAGS = -march=rv64im -mabi=lp64 -Wall
RUSTFLAGS = --target=riscv64gc-unknown-none-elf
LDFLAGS = -T link.lda

BUILD_DIR = target/riscv64gc-unknown-none-elf/release

QEMU_FLAGS = -machine virt -nographic -bios none -display sdl

all: $(BUILD_DIR)/$(TARGET)

%.o: %.S
	$(CROSS)as $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/bootloader.o: src/main.rs
	cargo clean
	cargo build --target=riscv64gc-unknown-none-elf --release --no-default-features -v
	# Check if the cargo build command was successful
	if [ $$? -eq 0 ]; then \
		echo "Cargo build successful"; \
	else \
		echo "Error: Cargo build failed"; \
		exit 1; \
	fi
	ls -l $(BUILD_DIR)/deps/
	# The object file should be named after the package
	cp $(BUILD_DIR)/deps/bootloader-c0ef28f19971401b $(BUILD_DIR)/bootloader.o

boot.o: boot.S
	$(CROSS)as $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/$(TARGET): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CROSS)ld $(LDFLAGS) -o $@ $(OBJS)

bin: $(BUILD_DIR)/$(TARGET)
	$(CROSS)objcopy -O binary $< $(BIN)

run: all
	qemu-system-riscv64 $(QEMU_FLAGS) -kernel $(BUILD_DIR)/$(TARGET)

run-bios: bin
	qemu-system-riscv64 $(QEMU_FLAGS) -bios $(BIN)

clean:
	rm -f *.o *.bin
	rm -f $(BUILD_DIR)/$(TARGET)
	rm -f $(BUILD_DIR)/bootloader.o
	rm -rf $(BUILD_DIR)/deps/