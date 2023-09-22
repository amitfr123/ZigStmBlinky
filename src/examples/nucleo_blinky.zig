const regs = @import("../registers/stm32f446.zig");

pub fn blinky() void {
    // Enable GPIOA port
    regs.RCC.AHB1ENR.modify(.{ .GPIOAEN = 1 });

    // Set pin 5 mode to general purpose output
    regs.GPIOA.MODER.modify(.{ .MODER5 = 0b01 });
    while (true) {
        // Read the LED state
        var leds_state = regs.GPIOA.ODR.read();
        // Set the LED output to the negation of the currrent output
        regs.GPIOA.ODR.modify(.{
            .ODR5 = ~leds_state.ODR5,
        });
        var i: u32 = 0;
        while (i < 600000) {
            asm volatile ("nop");
            i += 1;
        }
    }
}
