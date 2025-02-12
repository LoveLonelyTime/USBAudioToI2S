module spi_slave (
    input clk,
    input nrst,

    input spi_ck,
    input spi_mosi,
    output reg spi_miso,
    input spi_nss,

    // Control
    output reg [2:0] clk_sel
);

  // Metastability guard
  reg spi_ck_ms;
  reg spi_mosi_ms;
  reg spi_nss_ms;

  // Sample
  reg spi_ck_sample;
  reg spi_mosi_sample;
  reg spi_nss_sample;
  reg spi_ck_sample_d;

  // FSM
  reg [2:0] state;
  localparam S_IDLE = 3'b001;
  localparam S_TRANS = 3'b010;
  localparam S_RESP = 3'b100;

  reg [2:0] cnt;
  reg [7:0] data_in;
  reg [7:0] data_out;

  always @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      state <= 0;
      cnt <= 0;
      data_in <= 0;
      data_out <= 0;
      clk_sel <= 0;

      spi_ck_ms <= 0;
      spi_mosi_ms <= 0;
      spi_nss_ms <= 0;
      spi_ck_sample <= 0;
      spi_mosi_sample <= 0;
      spi_nss_sample <= 0;
      spi_ck_sample_d <= 0;
      spi_miso <= 0;
    end else begin
      // Sampling
      spi_ck_ms <= spi_ck;
      spi_mosi_ms <= spi_mosi;
      spi_nss_ms <= spi_nss;

      spi_ck_sample <= spi_ck_ms;
      spi_mosi_sample <= spi_mosi_ms;
      spi_nss_sample <= spi_nss_ms;

      spi_ck_sample_d <= spi_ck_sample;

      case (state)
        S_IDLE: begin
          if (~spi_nss_sample) begin  // Activate
            state <= S_TRANS;
            cnt <= 7;
            spi_miso <= data_out[7];
          end
        end

        S_TRANS: begin
          if (spi_nss_sample) begin
            state <= S_IDLE;
          end else begin
            if (~spi_ck_sample_d & spi_ck_sample) begin  // Up
              data_in[cnt] <= spi_mosi_sample;
              cnt <= cnt - 1;
              if (cnt == 0) state <= S_RESP;
            end

            if (spi_ck_sample_d & ~spi_ck_sample) begin  // Down
              spi_miso <= data_out[cnt];
            end
          end
        end

        S_RESP: begin
          if (spi_nss_sample) state <= S_IDLE;  // Deactivate

          // Response
          // Inst: 7:5 | Param: 4:0

          case (data_in[7:5])
            // Get status: 001
            3'b001: begin
              // Ready: 7 | Version: 6:0
              data_out <= 8'b10000001;
            end

            // Set format: 010
            3'b010: begin
              clk_sel  <= data_in[2:0];
              // Ready: 7
              data_out <= 8'b10000000;
            end

            // Get format: 011
            3'b011: begin
              // Ready: 7 | Format: 2:0
              data_out <= {5'b10000, clk_sel};
            end

            default: data_out <= 0;  // Error
          endcase
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
