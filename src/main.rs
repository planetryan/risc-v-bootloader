#![no_std]
#![no_main]

use core::panic::PanicInfo;

const MTIME: *const u64 = 0x0200_BFF8 as *const u64;
const POWER_OFF: *mut u32 = 0x100000 as *mut u32;

// based on QEMU's default timer frequency (usually 10 MHz)
const TICKS_PER_SECOND: u64 = 10_000_000;
const SECONDS_TO_WAIT: u64 = 5;

#[no_mangle]
pub extern "C" fn _start_rust() -> ! {
    let start = unsafe { core::ptr::read_volatile(MTIME) };
    let end = start + SECONDS_TO_WAIT * TICKS_PER_SECOND;

    while unsafe { core::ptr::read_volatile(MTIME) } < end {}

    unsafe {
        core::ptr::write_volatile(POWER_OFF, 0x5555);
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
