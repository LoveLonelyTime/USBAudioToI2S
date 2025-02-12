// TOP
module audio_cpld (
    // Clocks
    input clk,  // 24.576 MHz
    input sub_clk,  // 22.5792 MHz

    // I2S input
    input in_ws,
    input in_ck,
    input in_sd,

    // I2S output
    output out_mck,
    output out_ws,
    output out_ck,
    output out_sd,

    // Feedback
    output buffer_empty,
    output buffer_full,

    // SPI
    input  spi_ck,
    input  spi_mosi,
    output spi_miso,
    input  spi_nss
);
  // Reset
  wire nrst;

  // Disable MCK
  assign out_mck = 0;

  // PLL clocks
  wire pll_main_clk;
  wire pll_out2;  // Mul2: 384KHz
  wire pll_out1;  // Mul1: 192KHz
  wire pll_outd2;  // Div2: 96KHz
  wire pll_outd4;  // Div4: 48KHz
  wire sub_out1;  // Mul1: 176.4KHz
  wire sub_outd2;  // Div2: 88.2KHz
  wire sub_outd4;  // Div4: 44.1KHz
  wire [2:0] clk_sel;
  wire out_clk;

  // I2S input
  wire [31:0] i2s_in_left_channel;
  wire [31:0] i2s_in_right_channel;
  wire i2s_in_en;

  // FIFO
  wire fifo_full;
  wire [63:0] fifo_in;
  wire [63:0] fifo_out;
  wire fifo_in_en;
  wire fifo_empty;
  wire fifo_out_en;
  wire fifo_full_aux;

  // I2S output
  wire i2s_out_en;
  wire [31:0] i2s_out_left_channel;
  wire [31:0] i2s_out_right_channel;

  reset main_reset (
      .clk (clk),
      .nrst(nrst)
  );

  pll main_pll (
      .inclk0(clk),
      .c0(pll_out2),
      .c1(pll_out1),
      .c2(pll_outd2),
      .c3(pll_outd4),
      .c4(pll_main_clk),
  );

  clkdiv4 clkdiv4 (
      .inclk(sub_clk),
      .out1 (sub_out1),
      .outd2(sub_outd2),
      .outd4(sub_outd4)
  );

  clk_sel main_clk_sel (
      .nrst(nrst),
      .pll_main_clk(pll_main_clk),
      .pll_out2(pll_out2),
      .pll_out1(pll_out1),
      .pll_outd2(pll_outd2),
      .pll_outd4(pll_outd4),
      .sub_out1(sub_out1),
      .sub_outd2(sub_outd2),
      .sub_outd4(sub_outd4),
      .clk_sel(clk_sel),
      .out_clk(out_clk)
  );

  // --- Synchronize with pll_main_clk ---

  i2s_slave i2s_slave (
      .nrst(nrst),
      .clk(pll_main_clk),
      .i2s_ws(in_ws),
      .i2s_ck(in_ck),
      .i2s_sd(in_sd),
      .en(i2s_in_en),
      .left_channel(i2s_in_left_channel),
      .right_channel(i2s_in_right_channel)
  );

  recv_buffer recv_buffer (
      .clk(pll_main_clk),
      .nrst(nrst),
      .en(i2s_in_en),
      // Correction data
      // Swap left and right channels? Why???
      // Swap byte order
      .left_channel({i2s_in_right_channel[15:0], i2s_in_right_channel[31:16]}),
      .right_channel({i2s_in_left_channel[15:0], i2s_in_left_channel[31:16]}),
      .fifo_full(fifo_full),
      .data(fifo_in),
      .fifo_en(fifo_in_en)
  );

  fifo main_fifo (
      // Read
      .rdclk(out_clk),
      .rdreq(fifo_out_en),
      .data(fifo_in),
      // Write
      .wrclk(pll_main_clk),
      .wrreq(fifo_in_en),
      .q(fifo_out),
      // Flags
      .rdempty(fifo_empty),
      .wrfull(fifo_full),
      .rdfull(fifo_full_aux)
  );

  // --- Synchronize with out_clk ---

  trans_buffer trans_buffer (
      .clk(out_clk),
      .nrst(nrst),
      .en(i2s_out_en),
      .left_channel(i2s_out_left_channel),
      .right_channel(i2s_out_right_channel),
      .fifo_empty(fifo_empty),
      .data(fifo_out),
      .fifo_en(fifo_out_en)
  );

  i2s_master i2s_master (
      .clk(out_clk),
      .nrst(nrst),
      .en(i2s_out_en),
      .left_channel(i2s_out_left_channel),
      .right_channel(i2s_out_right_channel),
      .i2s_ws(out_ws),
      .i2s_ck(out_ck),
      .i2s_sd(out_sd)
  );

  spi_slave spi_slave (
      .clk(pll_main_clk),
      .nrst(nrst),
      .spi_ck(spi_ck),
      .spi_mosi(spi_mosi),
      .spi_miso(spi_miso),
      .spi_nss(spi_nss),
      .clk_sel(clk_sel)
  );

  pulse full_pulse (
      .clk (out_clk),
      .nrst(nrst),
      .en  (fifo_full_aux),
      .out (buffer_full)
  );

  pulse empty_pulse (
      .clk (out_clk),
      .nrst(nrst),
      .en  (fifo_empty),
      .out (buffer_empty)
  );

endmodule
