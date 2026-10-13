`timescale 1ns / 1ps

module ila_monitor(
    input clk,
    input [3:0] leds,
    input timer_interrupt,
    input timer_genout,
    input rst,
    input clk_locked
    );
    
    ila_0 ila_inst(
    .clk(clk),
    .probe0(leds),
    .probe1(timer_interrupt),
    .probe2(timer_genout),
    .probe3(rst),
    .probe4(clk_locked)
    );
    
endmodule
