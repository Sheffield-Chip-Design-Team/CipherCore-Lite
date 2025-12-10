// Synchroinizer for asynchronous rx input
// Defaults to 2-stage synchronizer

module synchronizer #(
  parameter integer STAGES = 2
)(
  input  wire  clk,
  input  wire  async_in,
  output reg   sync_out
);

  integer i;
  reg [STAGES-1:0] meta_flops;

  always @(posedge clk) begin
    // stage 0 captures the asynchronous input
    meta_flops[0] <= async_in;
   
    // propagate through remaining stages
    for (i = 1; i < STAGES; i = i + 1) begin
      meta_flops[i] <= meta_flops[i-1];
    end

    // output is the last stage
    sync_out <= meta_flops[(STAGES-1)];
  end
endmodule