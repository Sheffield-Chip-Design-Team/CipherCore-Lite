/*
 * Copyright (c) 2024 James Ashie Kotey
 * SPDX-License-Identifier: Apache-2.0
 */

module CipherCore_Top (
    input wire         clk,             
    input wire         rst_n,
    input wire         rx_in,
    output wire  [7:0] rx_data,
    output wire        done,
    output wire        valid
);
    
    wire rx_sync;

    synchronizer #(
        .STAGES(2)
    ) sync_rx_in (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(rx_in),
        .sync_out(rx_sync)
    );

    uart_rx #(
        .CLK_FREQ(30_000_000),
        .BAUD(9600)           
    ) rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx_sync),            
        .rx_data(rx_data),       
        .done(done),          
        .valid(valid)          
    );

endmodule
