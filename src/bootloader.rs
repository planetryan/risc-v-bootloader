#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

fn memory_setup() {
    // You can initialize memory, map regions, etc.
}

fn jump_to_kernel() {
    let kernel_entry_point: usize = 0x80000000;
    unsafe {
        let kernel_fn: fn() = core::mem::transmute(kernel_entry_point as *const ());
        kernel_fn();
    }
}

#[no_mangle]
pub extern "C" fn rust_start() -> ! {
    memory_setup();
    jump_to_kernel();
    loop {}
}
