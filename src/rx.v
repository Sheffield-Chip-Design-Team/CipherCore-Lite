// UART RECEIVINGr Module
// designed to work at 9600 Baud Rate with a 50MHz Clock

module uart_rx #(
    parameter CLK_FREQ   = 96000,
    parameter BAUD       = 9600,
    parameter OVERSAMPLE = 4     // Number of samples per bit
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,             // UART RX input line
    output wire [7:0] rx_data,        // RECEIVINGd byte
    output wire       done,        // asserted for one cycle when a byte is received
    output wire       valid        // asserted if the received byte is valid (no framing error)
);

  reg old_rx;

  // internal status signals
  reg rx_start;
  reg rx_in_prog;
  reg rx_done;
  reg rx_ready;

  // Latch received data
  reg frame_error;


  // data storage 
  localparam DATA_BITS = 8;
  localparam DATA_REG_WIDTH = $clog2(DATA_BITS);

  reg [DATA_BITS-1:0] rx_data_reg;
  reg [DATA_BITS-1:0] rx_data_buf;  // extra bit for start and stop bit storage stop bit checking
  
  // oversampling parameters
  localparam integer DIVIDER = CLK_FREQ / (BAUD);
  localparam integer DIVIDER_WIDTH = $clog2(DIVIDER);

  // oversample clock generation 
  reg [OVERSAMPLE-1:0] div_cnt = 0;
  reg                  sample_tick = 0;

  // FSM for RX logic
  localparam IDLE       = 2'b00;
  localparam START      = 2'b01;
  localparam RECEIVING  = 2'b10;
  localparam STOP   = 2'b11;

  reg [1:0]                state       = IDLE;
  reg [DATA_REG_WIDTH:0]   bit_index   = 0;     // to count the number of bits received 
  reg [DATA_REG_WIDTH:0]   data_index  = 0;     // to count the number of bits received 
  reg start_bit;
  reg stop_bit;

  // verilator lint_off WIDTHEXPAND

  // SAMPLE COUNTER FSM

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
        div_cnt <= div_cnt + 1;
      
        if (state == START) begin
          if (div_cnt[DIVIDER_WIDTH-1:0] == ((DIVIDER/2)-1)) begin
            sample_tick <= 1;
            div_cnt <= 0;
          end 
        end

        else if (state == RECEIVING || state ==  STOP) begin
          if (div_cnt[OVERSAMPLE-1:0] == (DIVIDER-1)) begin
            sample_tick <= 1;
            div_cnt <= 0;
          end
        end 
        
      end else begin
        div_cnt <= 0;
        sample_tick <= 0;
      end
      
    end
  end

  // edge detection fo rx_start
  always @(posedge clk ) begin
    old_rx <= rx;
  end

  always @(posedge clk) begin
      if (!rst_n) begin
        state <= IDLE;
        // status signals
        rx_ready <= 1;
        rx_in_prog <= 0;
        rx_start <= 0;
        bit_index <= 0;
        // data sampling signals
        data_index <= 0;
        rx_data_buf <= 0;
      end else begin
          case (state)
            IDLE: begin
              rx_done <= 0;
              if (old_rx & ~rx) begin // start bit detected
                state <= START;
                start_bit <= rx;
                rx_start <= 1;
                rx_in_prog <= 1;
                bit_index <= 0;
                rx_ready <= 0;
              end else begin
                rx_ready <= 0;
              end
            end
            START: begin
              rx_start <= 0;
              if (sample_tick) begin
                state <= RECEIVING;
                bit_index <= bit_index + 1;
              end
            end
            RECEIVING: begin
              if (bit_index == DATA_BITS+1) begin
                // last data bit received
                state <= STOP;
              end
              if (sample_tick & (bit_index < (DATA_BITS+1))) begin
                rx_data_buf[data_index[DATA_REG_WIDTH-1:0]] <= rx;
                bit_index  <= bit_index + 1;
                data_index <= data_index + 1;
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

  assign done = rx_done;
  assign valid = ~frame_error;
  assign rx_data = rx_data_reg;

  // verilator lint_on WIDTHEXPAND      

endmodule