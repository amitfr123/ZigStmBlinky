const hw = if (@import("BuildOptions").DISCOVERY) @import("discovery.zig") else @import("nucleo.zig");
const blinky = if (@import("BuildOptions").DISCOVERY) @import("examples/discovery_blinky.zig") else @import("examples/nucleo_blinky.zig");

pub fn zig_entry() void {
    hw.systemInit();
    blinky.blinky();
}
