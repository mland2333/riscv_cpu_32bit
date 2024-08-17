import "DPI-C" function void ifu_get_inst();
import "DPI-C" function void idu_decode_inst(input int inst);
module ysyx_20020207_IFU(
  input clock, reset,
  input [31:0] pc_in,
  input pc_ready,

  input  io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  
  output io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [31:0] io_master_rdata,

  output [31:0]inst, pc_out,
  output inst_valid
);
assign pc_out = io_master_araddr;

always@(posedge clock)begin
  if(io_master_rvalid)begin
    ifu_get_inst();
    idu_decode_inst(io_master_rdata);
  end
end
reg[31:0] _inst;
assign inst = _inst;
reg _inst_valid;
assign inst_valid = _inst_valid;


`ifndef CONFIG_ICACHE
reg _arvalid;
assign io_master_arvalid = _arvalid;
reg[31:0] araddr;
assign io_master_araddr = araddr;

assign io_master_rready = 1;
always@(posedge clock)begin
  if(reset)begin
    _inst <= 0;
    _inst_valid <= 0;
  end
  else if(io_master_rvalid)begin
    _inst <= io_master_rdata;
    _inst_valid <= 1;
  end
  else begin
    _inst_valid <= 0;
  end
end

always@(posedge clock)begin
  if(reset)
    _arvalid <= 0;
  else begin
    if(pc_ready)begin
      _arvalid <= 1;
      araddr <= pc_in;
    end
    else begin
      if(io_master_arready && _arvalid)
        _arvalid <= 0;
    end
  end
end
`else
wire inst_require = pc_ready;
ICACHE icache(
  .reset(reset),
  .clock(clock),
  .inst_require(inst_require),
  .pc(pc_in),
  .inst_valid(_inst_valid),
  .inst(_inst),
  .arvalid(io_master_arvalid),
  .arready(io_master_arready),
  .rvalid(io_master_rvalid),
  .rready(io_master_rready),
  .rdata(io_master_rdata),
  .araddr(io_master_araddr)
);
`endif

endmodule


