/*
 * Copyright (c) 2024 James Ashie Kotey
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_ciphercore_lite(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// TODO design register interface

 CipherCore_Top  cc_inst (
    .clk(clk),             
    .rst_n(rst_n),
    // rx
    .rx_in(ui_in[1]),    
    .rx_done(uo_out[4]),
    .rx_valid(uo_out[2]),
    // tx
    .tx_data(uio_out), 
    .tx_out(uo_out[0]),  // Example: connect tx_out to uo_out[0]
    .tx_busy(uo_out[3]),
    .tx_done(uo_out[1])
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;
  assign uio_oe = 8'hff; // All uio pins are outputs

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
