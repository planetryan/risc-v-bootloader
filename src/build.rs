// build.rs
fn main() {
    println!("cargo:rustc-link-arg=-nostdlib");
}