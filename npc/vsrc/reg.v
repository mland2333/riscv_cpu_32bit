module ysyx_20020207_RegisterFile #(
    ADDR_WIDTH = 1,
    DATA_WIDTH = 1
) (
    input clock,
    input in_valid,
    output [DATA_WIDTH-1:0] rdata1,
    input [ADDR_WIDTH-1:0] raddr1,
    output [DATA_WIDTH-1:0] rdata2,
    input [ADDR_WIDTH-1:0] raddr2,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] waddr,
    input wen
);
  reg [DATA_WIDTH-1:0] rf[2**ADDR_WIDTH-1:0];
  always @(posedge clock) begin
    if (in_valid && wen && waddr != 0) rf[waddr] <= wdata;
  end
  assign rf[0]  = 0;
  assign rdata1 = rf[raddr1];
  assign rdata2 = rf[raddr2];
endmodule
