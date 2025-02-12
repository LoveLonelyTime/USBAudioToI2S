module i2s_slave (
    input clk,
    input nrst,

    // I2S
    input i2s_ws,
    input i2s_ck,
    input i2s_sd,

    // FIFO
    output reg en,
    output reg [31:0] left_channel,
    output reg [31:0] right_channel
);

  // Metastability guard
  reg  i2s_ws_ms;
  reg  i2s_ck_ms;
  reg  i2s_sd_ms;

  // Sample
  reg  i2s_ws_sample;
  reg  i2s_ck_sample;
  reg  i2s_sd_sample;
  reg  i2s_ck_sample_d;
  reg  i2s_ws_sample_d;

  // Sampling
  wire i2s_sample;
  assign i2s_sample = ~i2s_ck_sample_d & i2s_ck_sample;

  // FSM
  reg [2:0] state;
  localparam S_RECOVERY = 3'b001;
  localparam S_LEFT = 3'b010;
  localparam S_RIGHT = 3'b100;

  reg [4:0] cnt;
  reg i2s_ws_pattern;

  always @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      en <= 0;
      left_channel <= 0;
      right_channel <= 0;
      state <= 0;
      cnt <= 0;
      i2s_ws_pattern <= 0;

      i2s_ws_ms <= 0;
      i2s_ck_ms <= 0;
      i2s_sd_ms <= 0;
      i2s_ws_sample <= 0;
      i2s_ck_sample <= 0;
      i2s_sd_sample <= 0;
      i2s_ck_sample_d <= 0;
      i2s_ws_sample_d <= 0;
    end else begin
      // Sampling
      i2s_ws_ms <= i2s_ws;
      i2s_ck_ms <= i2s_ck;
      i2s_sd_ms <= i2s_sd;

      i2s_ws_sample <= i2s_ws_ms;
      i2s_ck_sample <= i2s_ck_ms;
      i2s_sd_sample <= i2s_sd_ms;

      i2s_ck_sample_d <= i2s_ck_sample;

      if (i2s_sample) begin
        i2s_ws_sample_d <= i2s_ws_sample;
      end

      // FSM
      case (state)
        S_RECOVERY: begin
          if (i2s_sample & i2s_ws_sample_d & ~i2s_ws_sample) begin  // Sync
            state <= S_LEFT;
            cnt <= 31;
            i2s_ws_pattern <= 0;
          end
        end

        S_LEFT: begin
          en <= 0;
          if (i2s_sample) begin
            left_channel[cnt] <= i2s_sd_sample;
            i2s_ws_pattern <= i2s_ws_pattern | i2s_ws_sample;
            cnt <= cnt - 1;

            if (cnt == 0) begin
              if (~i2s_ws_pattern & i2s_ws_sample) begin  // OK
                state <= S_RIGHT;
                cnt <= 31;
                i2s_ws_pattern <= 1;
              end else state <= S_RECOVERY;  // Error
            end
          end
        end

        S_RIGHT: begin
          if (i2s_sample) begin
            right_channel[cnt] <= i2s_sd_sample;
            i2s_ws_pattern <= i2s_ws_pattern & i2s_ws_sample;
            cnt <= cnt - 1;

            if (cnt == 0) begin
              if (i2s_ws_pattern & ~i2s_ws_sample) begin  // OK
                state <= S_LEFT;
                cnt <= 31;
                i2s_ws_pattern <= 0;

                en <= 1;
              end else state <= S_RECOVERY;  // Error
            end
          end
        end

        default: state <= S_RECOVERY;
      endcase
    end
  end

endmodule
