module i2s_master (
    input nrst,
    input clk,

    output reg en,
    input [31:0] left_channel,
    input [31:0] right_channel,

    output reg i2s_ws,
    output reg i2s_ck,
    output reg i2s_sd
);

  // FSM
  reg [3:0] state;
  localparam S_LEFT_UP = 4'b0001;
  localparam S_LEFT_DOWN = 4'b0010;
  localparam S_RIGHT_UP = 4'b0100;
  localparam S_RIGHT_DOWN = 4'b1000;

  reg [31:0] left_channel_reg;
  reg [31:0] right_channel_reg;
  reg [ 4:0] cnt;

  always @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      en <= 0;
      state <= 0;
      left_channel_reg <= 0;
      right_channel_reg <= 0;
      cnt <= 31;
      i2s_ws <= 0;
      i2s_ck <= 0;
      i2s_sd <= 0;
    end else begin
      // FSM
      case (state)
        S_LEFT_UP: begin
          i2s_ck <= 0;
          i2s_sd <= left_channel_reg[cnt];
          state  <= S_LEFT_DOWN;
          if (cnt == 0) i2s_ws <= 1;
        end

        S_LEFT_DOWN: begin
          i2s_ck <= 1;
          if (cnt == 0) begin
            state <= S_RIGHT_UP;
            cnt   <= 31;
          end else begin
            state <= S_LEFT_UP;
            cnt   <= cnt - 1;
          end
        end

        S_RIGHT_UP: begin
          i2s_ck <= 0;
          i2s_sd <= right_channel_reg[cnt];
          state  <= S_RIGHT_DOWN;
          if (cnt == 0) begin
            i2s_ws <= 0;
            en <= 1;
          end
        end

        S_RIGHT_DOWN: begin
          i2s_ck <= 1;
          if (cnt == 0) begin
            state <= S_LEFT_UP;
            cnt <= 31;
            left_channel_reg <= left_channel;
            right_channel_reg <= right_channel;
            en <= 0;
          end else begin
            state <= S_RIGHT_UP;
            cnt   <= cnt - 1;
          end
        end

        default: state <= S_LEFT_UP;
      endcase
    end
  end

endmodule
