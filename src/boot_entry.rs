#![no_std]
#![no_main]

use core::panic::PanicInfo;

extern "C" {
    static mut __bss_start: u64;
    static mut __bss_end: u64;
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

fn clear_bss() {
    unsafe {
        let mut bss = &mut __bss_start as *mut u64;
        while bss < &mut __bss_end as *mut u64 {
            bss.write_volatile(0);
            bss = bss.add(1);
        }
    }
}

fn memory_setup() {
    clear_bss();
}

fn jump_to_kernel() {
    let kernel_entry: usize = 0x80000000;
    unsafe {
        let kernel_fn: fn() = core::mem::transmute(kernel_entry as *const ());
        kernel_fn();
    }
}

#[no_mangle]
pub extern "C" fn rust_start() -> ! {
    memory_setup();
    jump_to_kernel();
    loop {}
}
