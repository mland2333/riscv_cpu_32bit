module ysyx_20020207_RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk, rst, lsu_finish,
  output [DATA_WIDTH-1:0] rdata1,
  input [ADDR_WIDTH-1:0] raddr1,
  output [DATA_WIDTH-1:0] rdata2,
  input [ADDR_WIDTH-1:0] raddr2,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  always @(posedge clk) begin
    if(rst) rf[2] <= 32'h0f002000;
    if (lsu_finish && wen && waddr!=0) rf[waddr] <= wdata;
  end
  always @(*)begin
      rf[0] = 0;
  end
  assign rdata1 = rf[raddr1];
  assign rdata2 = rf[raddr2];
endmodule
