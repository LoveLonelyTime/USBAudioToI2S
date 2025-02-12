module clk_sel (
    input nrst,
    input pll_main_clk,
    input pll_out2,
    input pll_out1,
    input pll_outd2,
    input pll_outd4,
    input sub_out1,
    input sub_outd2,
    input sub_outd4,

    input [2:0] clk_sel,
    output reg out_clk
);

  // TODO: Sync
  always @(*) begin
    case (clk_sel)
      3'b001:  out_clk = pll_out2;
      3'b010:  out_clk = pll_out1;
      3'b011:  out_clk = pll_outd2;
      3'b100:  out_clk = pll_outd4;
      3'b101:  out_clk = sub_out1;
      3'b110:  out_clk = sub_outd2;
      3'b111:  out_clk = sub_outd4;
      default: out_clk = pll_out2;
    endcase
  end

endmodule
