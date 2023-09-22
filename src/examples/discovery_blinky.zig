const regs = @import("../registers/stm32f407.zig");

pub fn blinky() void {
    // Enable GPIOD port
    regs.RCC.AHB1ENR.modify(.{ .GPIODEN = 1 });

    // Set pin 12/13/14/15 mode to general purpose output
    regs.GPIOD.MODER.modify(.{ .MODER12 = 0b01, .MODER13 = 0b01, .MODER14 = 0b01, .MODER15 = 0b01 });
    // Set pin 12 and 14 for a nice effect
    regs.GPIOD.BSRR.modify(.{ .BS12 = 1, .BS14 = 1 });
    while (true) {
        // Read the LED state
        var leds_state = regs.GPIOD.ODR.read();
        // Set the LED output to the negation of the currrent output
        regs.GPIOD.ODR.modify(.{
            .ODR12 = ~leds_state.ODR12,
            .ODR13 = ~leds_state.ODR13,
            .ODR14 = ~leds_state.ODR14,
            .ODR15 = ~leds_state.ODR15,
        });
        var i: u32 = 0;
        while (i < 600000) {
            asm volatile ("nop");
            i += 1;
        }
    }
}
