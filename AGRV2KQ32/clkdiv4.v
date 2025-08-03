module clkdiv4(
    input inclk,
    output out1,
    output outd2,
    output outd4,
    output outd8
);
reg [2:0] cnt;

assign out1 = inclk;
assign outd2 = cnt[0];
assign outd4 = cnt[1];
assign outd8 = cnt[2];

always @(posedge inclk) begin
    cnt <= cnt + 1'b1;
end

endmodule