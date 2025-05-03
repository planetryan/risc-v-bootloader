This project is a minimal bootloader for RISC-V written in Rust and Risc-V Assembly. It's designed to load in a bare metal, no BIOS, etc. enviorment in QEMU and optionally loads a kernel image.

You can compile by using the Makefile, 
If that does NOT work for whatever reason, you can use Cargo to compile.

Here is how:

1: cd into risc-v directory

2: paste this Cargo command:

cargo build --target=riscv64gc-unknown-none-elf --release --no-default-features -v

3: Check if it runs With QEMU or physical RISC-V board:

 qemu-system-riscv64 -machine virt -bios none -kernel target/riscv64gc-unknown-none-elf/release/bootloader

4: Use cargo clean to remove compiled binaries.
