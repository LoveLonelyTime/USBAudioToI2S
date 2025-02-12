module pulse (
    input clk,
    input nrst,
    input en,
    output reg out
);

  reg state;

  always @(posedge clk, negedge nrst) begin
    if (!nrst) begin
      out   <= 0;
      state <= 0;
    end else begin
      if (~state && en) begin
        out   <= 1;
        state <= 1;
      end

      if (state) begin
        state <= 0;
        out   <= 0;
      end
    end
  end
endmodule
