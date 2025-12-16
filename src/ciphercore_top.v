/*
 * Copyright (c) 2024 James Ashie Kotey
 * SPDX-License-Identifier: Apache-2.0
 */

module CipherCore_Top (

    input  wire         clk,             
    input  wire         rst_n,
    // rx interface
    input  wire         rx_in,
    output wire  [7:0]  rx_data,
    output wire         rx_done,
    output wire         rx_valid,
    // tx interface
    output wire         tx_out,
    output wire         tx_done,
    output wire         tx_busy
);

   wire rx_sync;
   reg old_rx_done;
    
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
        .done(rx_done),          
        .valid(rx_valid)          
    );
    
    always @(posedge clk) begin
      old_rx_done <= rx_done;
    end
 
    uart_tx #(
        .CLK_FREQ(30_000_000),
        .CYCLES_PER_BIT(3125)           
    ) tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(old_rx_done),
        .tx_data(rx_data),       
        .tx(tx_out),            
        .busy(tx_busy),          
        .done(tx_done)          
    );


endmodule
