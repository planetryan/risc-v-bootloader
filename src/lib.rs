#![no_std]
#![crate_type = "staticlib"]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

extern "C" {
    static __bss_start: u64;
    static __bss_end: u64;
}

fn zero_bss() {
    unsafe {
        let mut bss = &__bss_start as *const u64 as *mut u64;
        while bss < &__bss_end as *const u64 as *mut u64 {
            *bss = 0;
            bss = bss.offset(1);
        }
    }
}

fn memory_setup() {
    zero_bss();
    // Initialize memory (MMU setup, etc. if needed)
}

fn jump_to_kernel() {
    let kernel_entry_point: usize = 0x80000000;
    unsafe {
        let entry_point = kernel_entry_point as *const ();
        let kernel_fn: fn() = core::mem::transmute(entry_point);
        kernel_fn();
    }
}

#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    memory_setup();
    jump_to_kernel();
    loop {}
}