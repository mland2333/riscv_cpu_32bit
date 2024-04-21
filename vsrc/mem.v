import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module Memory(
  input[31:0] raddr, waddr, wdata,
  input valid, wen, 
  input [7:0] wmask,
  output reg[31:0] rdata
);
always @(*) begin
  if (valid) begin // 有读写请求时
    rdata = pmem_read(raddr);
    if (wen) begin // 有写请求时
      pmem_write(waddr, wdata, wmask);
      //$display("write\n");
    end
  end
  else begin
    rdata = 0;
  end
end

endmodule

/*module MemFile #(ADDR_WIDTH = 8, DATA_WIDTH = 32) (
  input [ADDR_WIDTH-1:0] raddr,
  input [ADDR_WIDTH-1:0] waddr,
  input [DATA_WIDTH-1:0] wdata,
  input wen,
  output [DATA_WIDTH-1:0] rdata
);
  reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
  always @(*) begin
    mem[waddr] = wdata;
  end
  assign rdata = mem[raddr];
endmodule */
