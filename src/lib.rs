#![no_std]

use core::panic::PanicInfo;
use core::ptr;
use volatile::Volatile;
use core::arch::global_asm;

global_asm!(
    ".global _start",
    "_start:",
    "call main"
);

extern "C" {
    static mut __bss_start: u64;
    static mut __bss_end: u64;
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // THIS MAKES NO SENSE, WHY IS THIS A ERROR
    loop {}
}

fn clear_bss() {
    unsafe {
        let mut bss = &raw mut __bss_start as *mut u64;
        while bss < &raw mut __bss_end as *mut u64 {
            ptr::write_volatile(bss, 0);
            bss = bss.add(1);
        }
    }
}

fn memory_setup() {
    clear_bss();
}

const UART_MMIO_BASE: usize = 0x10000000;

fn read_disk_sector(_sector: u64, _buffer: *mut u8) {
    println("read_disk_sector called");
}

#[repr(C)]
struct Elf64Header {
    e_ident: [u8; 16],
    e_type: u16,
    e_machine: u16,
    e_version: u32,
    e_entry: u64,
    e_phoff: u64,
    e_shoff: u64,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
}

fn parse_elf(elf_data: *const u8) -> usize {
    let elf_header = unsafe { &*(elf_data as *const Elf64Header) };
    println("parse_elf called");
    elf_header.e_entry as usize
}

fn println(s: &str) {
    for byte in s.bytes() {
        unsafe {
            let uart = &mut *(UART_MMIO_BASE as *mut Volatile<u8>);
            uart.write(byte);
        }
    }
    unsafe {
        let uart = &mut *(UART_MMIO_BASE as *mut Volatile<u8>);
        uart.write('\n' as u8);
    }
}

fn generate_signal() {
    let signal: [u8; 8] = [0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF];

    for byte in signal.iter() {
        unsafe {
            let uart = &mut *(UART_MMIO_BASE as *mut Volatile<u8>);
            uart.write(*byte);
        }
    }
}

#[no_mangle]
pub extern "C" fn main() -> ! {
    memory_setup();

    println("Bootloader started");
    generate_signal();

    let mut elf_buffer: [u8; 65536] = [0; 65536];
    let elf_data = elf_buffer.as_mut_ptr();
    read_disk_sector(1, elf_data);

    let entry_point = parse_elf(elf_data);

    println("Jumping to kernel");
    let kernel_entry: fn() = unsafe { core::mem::transmute(entry_point as *const ()) };
    kernel_entry();

    loop {}
}