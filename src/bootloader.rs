#![no_std] 
#![no_main] 

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

fn memory_setup() {}

fn jump_to_kernel() {
    let kernel_entry_point: usize = 0x80000000; 
    unsafe {
        let entry_point = kernel_entry_point as *const ();
        let kernel_fn: fn() = core::mem::transmute(entry_point);
        kernel_fn();
    }
}

#[no_mangle] 
pub extern "C" fn _start() -> ! {
    memory_setup();
    jump_to_kernel();
    loop {}
}
