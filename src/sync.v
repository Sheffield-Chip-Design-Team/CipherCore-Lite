// CDC Synchroinizer Module
// Defaults to 2-stage synchronizer

module synchronizer #(
  parameter integer STAGES = 2
)(
  input  wire  clk,
  input  wire  rst_n,
  input  wire  async_in,
  output reg   sync_out
);

  integer i;
  reg [STAGES-1:0] meta_flops;

  always @(posedge clk) begin
    if (!rst_n) begin
        meta_flops <= 0;
    end else begin
        // stage 0 captures the asynchronous input
        meta_flops[0] <= async_in;
        // propagate through remaining stages
        for (i = 1; i < STAGES; i = i + 1) begin
          meta_flops[i] <= meta_flops[i-1];
        end
    end
  end
  
  always @(*) begin
    // output is the last stage
    sync_out <= meta_flops[(STAGES-1)];
  end 
  
endmodule