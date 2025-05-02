fn main() {
    println!("cargo:rustc-linker=riscv64-unknown-elf-gcc");
    println!("cargo:rustc-link-arg=-Tlink.ld");
    println!("cargo:rerun-if-changed=build.rs");
}
