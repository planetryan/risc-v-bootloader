CROSS = riscv64-unknown-elf-

OBJS = start.o main.o 
TARGET = bootloader.elf

# Flags
ASFLAGS = -march=rv64im -mabi=lp64 -Wall
RUSTFLAGS = --target=riscv64gc-unknown-none-elf
LDFLAGS = -T link.ld 

BUILD_DIR = target/riscv64gc-unknown-none-elf/release

# QEMU options
QEMU_FLAGS = -machine virt -nographic -bios none -display sdl

all: $(TARGET)

%.o: %.S
	$(CROSS)as $(ASFLAGS) -o $@ $<

main.o: src/main.rs
	cargo build --target=riscv64gc-unknown-none-elf --release
	cp target/riscv64gc-unknown-none-elf/release/deps/bootloader-*.o src/main.o

$(TARGET): $(OBJS)
	$(CROSS)ld $(LDFLAGS) -o $(BUILD_DIR)/$(TARGET) $^

# Run QEMU
run: $(TARGET)
	qemu-system-riscv64 $(QEMU_FLAGS) -kernel $(BUILD_DIR)/$(TARGET)

clean:
	rm -f $(OBJS) $(BUILD_DIR)/$(TARGET)
	rm -f target/riscv64gc-unknown-none-elf/release/*.o
