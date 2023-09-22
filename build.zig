const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    };
    const optimize = std.builtin.Mode.Debug;

    const elf = b.addExecutable(.{ .name = "app.elf", .root_source_file = .{ .path = "src/startup.zig" }, .target = target, .optimize = optimize });

    const vector_obj = b.addObject(.{ .name = "vector", .root_source_file = .{ .path = "src/vector.zig" }, .target = target, .optimize = optimize });

    const opt = b.addOptions();
    var hw_type = b.option(bool, "discovery", "build for discovery board") orelse false;
    const qemu_build = b.option(bool, "qemu", "build for qemu") orelse false;
    // there is no qemu profile for the nocleo
    hw_type = hw_type or qemu_build;
    opt.addOption(bool, "DISCOVERY", hw_type);
    opt.addOption(bool, "QEMU", qemu_build);
    elf.addOptions("BuildOptions", opt);

    elf.addObject(vector_obj);
    if (hw_type) {
        elf.setLinkerScriptPath(.{ .path = "src/link/STM32F407VGTx_FLASH.ld" });
    } else {
        elf.setLinkerScriptPath(.{ .path = "src/link/STM32F446RETx_FLASH.ld" });
    }
    b.installArtifact(elf);
    const bin = elf.addObjCopy(.{ .basename = "app.bin", .format = .bin });

    const bin_step = b.step("bin", "Generate binary file to be flashed");
    bin_step.dependOn(&elf.step);
    b.getInstallStep().dependOn(&bin.step);

    const qemu_r = b.addSystemCommand(&[_][]const u8{ "qemu-system-gnuarmeclipse", "-M", "STM32F4-Discovery", "-m", "128M", "-kernel", "zig-out/bin/app.elf" });
    qemu_r.step.dependOn(b.getInstallStep());
    const run_step = b.step("qemu_run", "Run the app");
    run_step.dependOn(&qemu_r.step);

    const qemu = b.addSystemCommand(&[_][]const u8{ "qemu-system-gnuarmeclipse", "-M", "STM32F4-Discovery", "-m", "128M", "-kernel", "zig-out/bin/app.elf", "-s", "-S" });
    qemu.step.dependOn(b.getInstallStep());
    const qrun_step = b.step("qemu_debug", "Debug the app");
    qrun_step.dependOn(&qemu.step);

    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "write",
        "zig-out/bin/app.bin",
        "0x8000000",
    });
    flash_cmd.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash and run the app on your board");
    flash_step.dependOn(&flash_cmd.step);

    const dumpELFCommand = b.addSystemCommand(&[_][]const u8{
        "arm-none-eabi-objdump",
        "-D",
        "-m",
        "arm",
        "zig-out/bin/app.bin",
    });
    dumpELFCommand.step.dependOn(b.getInstallStep());
    const dumpELFStep = b.step("dump-elf", "Disassemble the ELF executable");
    dumpELFStep.dependOn(&dumpELFCommand.step);

    const dumpBinCommand = b.addSystemCommand(&[_][]const u8{
        "arm-none-eabi-objdump",
        "-D",
        "-m",
        "arm",
        "-b",
        "binary",
        "zig-out/bin/app.bin",
    });
    dumpBinCommand.step.dependOn(&bin.step);
    const dumpBinStep = b.step("dump-bin", "Disassemble the raw binary image");
    dumpBinStep.dependOn(&dumpBinCommand.step);
}
