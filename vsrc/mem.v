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


module LSU(
  input clk, rst, ifu_valid,
  input[31:0] raddr, waddr, wdata,
  input ren, wen, 
  input[7:0] wmask,
  input[2:0] load_ctl,
  output reg[31:0] rdata,
  output lsu_ready, lsu_valid
);
localparam IDLE = 2'b01;
localparam WAIT_READY = 2'b10;
reg[1:0] state;
reg[31:0] _rdata;
always@(posedge clk)begin
  if(rst)begin
    state <= IDLE;
  end
  else begin
    case(state)
      IDLE:begin
        lsu_valid <= 0;
        if(ifu_valid)begin
          lsu_ready <= 1;
          state <= WAIT_READY;
        end
      end
      WAIT_READY:begin
        if(ren) _rdata <= pmem_read(raddr);
        if(wen) pmem_write(waddr, wdata, wmask);
        lsu_ready <= 0;
        lsu_valid <= 1;
        state <= IDLE;
      end
      default:begin
        state <= 2'b00;
      end
    endcase
  end
end

always@(*)begin
  case(load_ctl)
    3'b000: rdata = {{24{_rdata[7]}}, _rdata[7:0]};
    3'b001: rdata = {{16{_rdata[15]}}, _rdata[15:0]};
    3'b010: rdata = _rdata;
    3'b100: rdata = {24'b0, _rdata[7:0]};
    3'b101: rdata = {16'b0, _rdata[15:0]};
    default: rdata = _rdata;
  endcase
end
endmodule

/*
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

endmodule*/
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
