module recv_buffer (
    input nrst,
    input clk,
    input en,
    input signed [31:0] left_channel,
    input signed [31:0] right_channel,
    input fifo_full,
    output [63:0] data,
    output fifo_en
);

  assign fifo_en = ~fifo_full & en;
  assign data = {left_channel, right_channel};

endmodule

module trans_buffer (
    input nrst,
    input clk,
    input en,
    output [31:0] left_channel,
    output [31:0] right_channel,
    input fifo_empty,
    input [63:0] data,
    output fifo_en
);

  // Smooth buffer
  reg [63:0] last_data;

  assign fifo_en = ~fifo_empty & en;
  assign left_channel = fifo_en ? data[31:0] : last_data[31:0];
  assign right_channel = fifo_en ? data[63:32] : last_data[63:32];

  always @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      last_data <= 0;
    end else begin
      if (fifo_en) begin
        last_data <= data;
      end
    end
  end

endmodule
