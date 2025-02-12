module reset (
    input clk,
    output reg nrst
);

  reg [4:0] reset_count;
  reg clear_counter;

  always @(posedge clk) begin
    clear_counter <= 0;

    nrst <= (reset_count == 31);

    if (clear_counter) reset_count <= 0;
    else if (reset_count != 31) reset_count <= reset_count + 1;
  end

endmodule
