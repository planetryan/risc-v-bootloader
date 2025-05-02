ENTRY(_start)

MEMORY
{
    TEXT (rx) : ORIGIN = 0x80000000, LENGTH = 16M
    DATA (rw) : ORIGIN = 0x82000000, LENGTH = 64M
}

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text*)
    } > TEXT

    .data : {
        *(.data*)
    } > DATA

    .bss : {
        *(.bss*)
        *(COMMON)
    } > DATA

    . = ALIGN(8);
    _end = .;
}
