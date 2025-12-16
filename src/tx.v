// Simple UART Transmitter Module
// Designed to work at 9600 Baud Rate with a 30MHz Clock (parameters can be adjusted)

module uart_tx #(
    parameter CLK_FREQ        = 30_000_000, // Clock frequency in Hz
    parameter CYCLES_PER_BIT  = 3125        // Cycles per bits (30MHz / 9600 Baud)
)(
    input  wire       clk,
    input  wire       rst_n,
    output wire       tx,             // UART TX output line
    input wire        tx_start,       // signal to start transmission of a byte
    input wire [7:0]  tx_data,        // input data to send 
    output wire       busy,           // asserted when transmitter is busy
    output wire       done            // asserted if the received byte is valid (no framing error)
);
  
  // internal signal to detect edges
  reg old_rx;

  // internal status signals
  reg old_tx_start;
  reg tx_reg;
  reg tx_in_prog;
  reg tx_done;
  
  // frame storage 
  localparam DATA_BITS = 8;
  localparam DATA_REG_WIDTH = $clog2(DATA_BITS);

  reg [DATA_BITS-1:0] tx_data_reg;
  reg                 parity_bit;

  // baud counter parameters
  localparam integer DIVIDER_WIDTH = $clog2(CYCLES_PER_BIT)+1;
  
  reg [DIVIDER_WIDTH-1:0] baud_cnt = 0;
  reg                     bit_period_tick = 0;

  // FSM for RX logic
  localparam IDLE    = 3'b000;
  localparam START   = 3'b001;
  localparam DATA    = 3'b010;
  localparam PARITY  = 3'b011;
  localparam STOP    = 3'b100;

  reg [2:0]                state       = IDLE;
  reg [DATA_REG_WIDTH:0]   bit_index   = 0;     // to count the number of bits received 
  reg [DATA_REG_WIDTH:0]   data_index  = 0;     // to count the number of bits received 

  // Bit Period Counter
  always @(posedge clk) begin
    if (!rst_n) begin
      baud_cnt         <= 0;
      bit_period_tick  <= 0;
    end else begin 
      if (tx_in_prog) begin
        if (baud_cnt[DIVIDER_WIDTH-1:0] == (CYCLES_PER_BIT-1)) begin
          bit_period_tick <= 1;
          baud_cnt <= 0;
        end else begin
          baud_cnt <= baud_cnt + 1;
          bit_period_tick <= 0;
        end
      end
      else begin
        baud_cnt <= 0;
        bit_period_tick <= 0;
      end
    end 
  end

  // Data Buffering 
  always @(posedge clk) begin
    if (!rst_n) begin
      tx_data_reg <= 0;
    end else begin
      if (tx_start && !tx_in_prog) begin
        tx_data_reg <= tx_data;
      end
    end
  end

  // Parity Calculation Trigger
 always @(posedge clk) begin
    if (!rst_n) begin
      old_tx_start <= 0;
    end else begin
       old_tx_start <= tx_start;
    end
  end

  // Parity Calculation
  always @(posedge clk) begin
    if (!rst_n) begin
      parity_bit <= 0;
    end else begin
      if (~tx_start && old_tx_start) begin
        parity_bit <= ~(^tx_data); // odd parity bit calculation
      end
    end
  end

  // Data Transmission FSM 
  always @(posedge clk) begin
      if (!rst_n) begin
        state <= IDLE;
        // status signals
        tx_in_prog  <= 0;
        bit_index   <= 0;
        // data sampling signals
        data_index  <= 0;
        tx_data_reg <= 0;
        tx_reg      <= 1; // idle state of tx line is high
      end else begin
          case (state)
            IDLE: begin
              tx_done    <= 1;
              tx_reg     <= 1; // idle state of tx line is high
              tx_in_prog <= 0;
              if (tx_start) begin
                tx_in_prog <= 1;
                state      <= START;
                bit_index  <= 0;
                data_index <= 0;
              end
            end
            START: begin
              tx_reg      <= 0; // start bit
              if (bit_period_tick) begin
                state     <= DATA;
                bit_index <= bit_index + 1;
              end
            end
            DATA: begin
              tx_reg  <= tx_data_reg[data_index[DATA_REG_WIDTH-1:0]];

              if (bit_period_tick) begin
                bit_index    <= bit_index + 1;
                // send data bits
                if (bit_index < (DATA_BITS)) begin
                  data_index <= data_index + 1;
                end
                // last data bit received
                if (bit_index == DATA_BITS) begin
                  state <= PARITY;
                end
              end
            end
            PARITY: begin
              tx_reg <= parity_bit;
              if (bit_period_tick) begin
                state     <= STOP;
                bit_index <= bit_index + 1;
              end
            end
            STOP: begin
              tx_reg <= 1'b1; // stop bit              
              if (bit_period_tick) begin
                state     <= IDLE;
                bit_index <= bit_index + 1;
                tx_done   <= 1;
              end
            end
            default: begin
              state <= IDLE;
            end
          endcase
        end
      end


  // Output assignments

  assign tx   = tx_reg;
  assign busy = tx_in_prog;
  assign done = tx_done;

  // verilator lint_on WIDTHEXPAND     

endmodule