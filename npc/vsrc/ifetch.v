import "DPI-C" function void ifu_get_inst();
import "DPI-C" function void idu_decode_inst(input int inst);
module ysyx_20020207_IFU(
  input clock, reset,
  input [31:0] pc,
  input pc_ready,

  input  io_master_arready,
  output reg io_master_arvalid,
  output [31:0] io_master_araddr,
  
  output io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [31:0] io_master_rdata,

  output reg [31:0] inst,
  output reg inst_valid
);

always@(posedge clock)begin
  if(io_master_rvalid)begin
    ifu_get_inst();
    idu_decode_inst(io_master_rdata);
  end
end

`ifndef CONFIG_ICACHE
assign io_master_araddr = pc;
assign io_master_rready = 1;
always@(posedge clock)begin
  if(reset)begin
    inst <= 0;
    inst_valid <= 0;
  end
  else if(io_master_rvalid)begin
    inst <= io_master_rdata;
    inst_valid <= 1;
  end
  else begin
    inst_valid <= 0;
  end
end

always@(posedge clock)begin
  if(reset)
    io_master_arvalid <= 0;
  else begin
    if(pc_ready)begin
      io_master_arvalid <= 1;
    end
    else begin
      if(io_master_arready && io_master_arvalid)
        io_master_arvalid <= 0;
    end
  end
end
`else
wire inst_require = pc_ready;
ICACHE icache(
  .reset(reset),
  .clock(clock),
  .inst_require(inst_require),
  .pc(pc),
  .inst_valid(inst_valid),
  .inst(inst),
  .arvalid(io_master_arvalid),
  .arready(io_master_arready),
  .rvalid(io_master_rvalid),
  .rready(io_master_rready),
  .rdata(io_master_rdata),
  .araddr(io_master_araddr)
);
`endif

endmodule


