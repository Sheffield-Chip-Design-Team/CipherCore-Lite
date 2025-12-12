/*
 * Copyright (c) 2024 James Ashie Kotey
 * SPDX-License-Identifier: Apache-2.0
 */

module CipherCore_FPGA_Top (
    input wire         clk,             
    input wire         rst_n,
    input wire         rx_in,
    output reg  [7:0]  rx_data,
    output wire        done,
    output wire        valid
);
    wire clk_30MHz;
    wire  [7:0] rx_data_plain;
    
    clk_div div
    (
      // Clock out ports
      .clk_in(clk),         // input clk_in
      .resetn(1'b1),        // don't reset the clk div (synchronous reset)
      .clk_out1(clk_30MHz)
    );
    
  CipherCore_Top ciphercore_inst (
      .clk(clk_30MHz),
      .rst_n(rst_n),
      .rx_in(rx_in),
      .rx_data(rx_data_plain),
      .done(done),
      .valid(valid)
  );
  
  // ADD encryption code here! 
  rx_data = rx_data_plain; 
  
  

endmodule
