// Simple UART Receiver Module
// Designed to work at 9600 Baud Rate with a 30MHz Clock (parameters can be adjusted)

module uart_rx #(
    parameter CLK_FREQ   = 30_000_000, // Clock frequency in Hz
    parameter BAUD       = 9600        // Baud rate in Hz
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,             // UART RX input line
    output wire [7:0] rx_data,        // Received Byte read out of the receiver
    output wire       done,           // asserted for one cycle when a byte is received
    output wire       valid            // asserted if the received byte is valid (no framing error)
);
  
  // internal signal to detect edges
  reg old_rx;

  // internal status signals
  reg rx_start;
  reg rx_in_prog;
  reg rx_done;
  reg rx_ready;
  reg parity_error;
  reg frame_error;

  // frame storage 
  localparam DATA_BITS = 8;
  localparam DATA_REG_WIDTH = $clog2(DATA_BITS);

  reg                 start_bit;
  reg [DATA_BITS-1:0] rx_data_reg;
  reg                 expected_parity;
  reg [DATA_BITS-1:0] rx_data_buf; 
  reg                 stop_bit;
  
  // oversampling parameters
  localparam integer DIVIDER = (CLK_FREQ / (BAUD));
  localparam integer DIVIDER_WIDTH = $clog2(DIVIDER)+1;

  // oversample clock generation 
  reg [DIVIDER_WIDTH-1:0] div_cnt = 0;
  reg                     sample_tick = 0;

  // FSM for RX logic
  localparam IDLE   = 3'b000;
  localparam START  = 3'b001;
  localparam DATA   = 3'b010;
  localparam PARITY = 3'b011;
  localparam STOP   = 3'b100;

  reg [2:0]                state       = IDLE;
  reg [DATA_REG_WIDTH:0]   bit_index   = 0;     // to count the number of bits received 
  reg [DATA_REG_WIDTH:0]   data_index  = 0;     // to count the number of bits received 

  // Sample tick generator
  always @(posedge clk) begin
    if (!rst_n) begin
        div_cnt <= 0;
        sample_tick <= 0;
    end else begin 
      
      if (rx_start) begin
        div_cnt <= 0;
        sample_tick <= 0;
      end 
      
      else if (rx_in_prog) begin
        
        sample_tick <= 0;
        div_cnt     <= div_cnt + 1;
      
        if (state == START) begin
          // verilator lint_off WIDTHEXPAND
          if (div_cnt == ((DIVIDER)/2)-1) begin
            sample_tick <= 1;
            div_cnt     <= 0;
          end 
        end

        else if (rx_in_prog) begin
          if (div_cnt == (DIVIDER-1)) begin
            sample_tick <= 1;
            div_cnt     <= 0;
          end
        end 
        
      end else begin
        div_cnt     <= 0;
        sample_tick <= 0;
      end
    end
  end

  // Edge detection for rx_start
  always @(posedge clk ) begin
    old_rx <= rx;
  end

  // Data Sampling FSM
  always @(posedge clk) begin
      if (!rst_n) begin
        state <= IDLE;
        // status signals
        rx_ready    <= 1;
        rx_in_prog  <= 0;
        rx_start    <= 0;
        bit_index   <= 0;
        // data sampling signals
        data_index      <= 0;
        rx_data_buf     <= 0;
        expected_parity <= 0;
      end else begin
          case (state)
            IDLE: begin
              rx_done       <= 0;
              if (old_rx & ~rx) begin // start bit detected
                state       <= START;
                start_bit   <= rx;
                rx_start    <= 1;
                rx_in_prog  <= 1;
                bit_index   <= 0;
                rx_ready    <= 0;
              end else begin
                rx_ready    <= 0;
              end
            end
            START: begin
              rx_start <= 0;
              if (sample_tick) begin
                state     <= DATA;
                bit_index <= bit_index + 1;
              end
            end
            DATA: begin
              if (sample_tick & (bit_index < (DATA_BITS+1))) begin
                rx_data_buf[data_index[DATA_REG_WIDTH-1:0]] <= rx;
                bit_index  <= bit_index + 1;
                data_index <= data_index + 1;
              end
              // last data bit received
              if (bit_index == DATA_BITS+1) begin
                state <= PARITY;
                expected_parity <= ~(^rx_data_buf); // odd parity bit calculation
              end
            end
            PARITY: begin
              if (sample_tick) begin
                bit_index <= bit_index + 1;
                // check parity bit
                if (rx != expected_parity) begin
                  frame_error <= 1;
                end
                state <= STOP;
              end
            end
            STOP: begin
              if (sample_tick) begin
                bit_index <= bit_index + 1;
                stop_bit <= rx;
                rx_in_prog <= 0;
                rx_done <= 1;
                state <= IDLE;
              end
            end
            default: begin
              state <= IDLE;
            end
          endcase
        end
      end

      // Latch received data and check for framing error
      always @(posedge clk) begin
        if (!rst_n) begin
          rx_data_reg <= 0;
          frame_error <= 0;
        end else begin
          if (rx_done) begin
            if (start_bit == 0 && stop_bit == 1) begin
                rx_data_reg <= rx_data_buf;
                frame_error <= 0;
            end else begin   
                frame_error <= 1;  
            end
          end
        end
      end

  // Output assignments
  assign done    = rx_done;
  assign valid   = ~frame_error;
  assign rx_data = rx_data_reg;

  // verilator lint_on WIDTHEXPAND     

endmodule