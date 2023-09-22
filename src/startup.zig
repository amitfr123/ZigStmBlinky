const main = @import("main.zig");

// These symbols come from the linker script
extern const _estack: c_uint;

// only f4 discovery
//extern const _siccmram: u32;
extern const _sidata: u32;

extern var _sdata: u32;
extern const _edata: u32;
extern var _sbss: u32;
extern const _ebss: u32;

export fn resetHandler() void {
    // setup stack pointer
    asm volatile ("mov r0, %[spt]"
        :
        : [spt] "r" (&_estack),
        : "r0"
    );
    asm volatile ("mov sp,r0");

    resetHandlerPart2();

    unreachable;
}

fn resetHandlerPart2() void {
    // Copy data from flash to RAM
    const data_loadaddr = @as([*]const u8, @ptrCast(&_sidata));
    const data = @as([*]u8, @ptrCast(&_sdata));
    const data_size = @intFromPtr(&_edata) - @intFromPtr(&_sdata);
    for (data_loadaddr[0..data_size], 0..) |d, i| data[i] = d;

    // Clear the bss
    const bss = @as([*]u8, @ptrCast(&_sbss));
    const bss_size = @intFromPtr(&_ebss) - @intFromPtr(&_sbss);
    for (bss[0..bss_size]) |*b| b.* = 0;

    // Call contained in main.zig
    main.zig_entry();

    unreachable;
}
