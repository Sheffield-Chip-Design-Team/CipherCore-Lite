/*
 * Copyright (c) 2024 James Ashie Kotey
 * SPDX-License-Identifier: Apache-2.0
 */

module CipherCore_FPGA_Top (

    input  wire         clk,             
    input  wire         rst_n,
    // rx interface
    input  wire         rx_in,
    output reg  [7:0]   rx_data,
    output wire         rx_done,
    output wire         rx_valid,
    // tx interface
    output reg          tx_out,
    output wire         tx_done,
    output wire         tx_busy
);

    wire clk_30MHz;
    
    clk_div div (
      .clk_in(clk),         // input clk_in
      .resetn(1'b1),        // don't reset the clk div (synchronous reset)
      .clk_out1(clk_30MHz)  // Clock out ports
    );
    
    CipherCore_Top ciphercore_inst (
      .clk(clk_30MHz),
      .rst_n(rst_n),
      .rx_in(rx_in),
      .rx_data(rx_data),
      .rx_done(rx_done),
      .rx_valid(rx_valid),
      .tx_out(tx_out),
      .tx_busy(tx_busy),
      .tx_done(tx_done),
      .rx_valid(rx_valid)
    );

  

endmodule
