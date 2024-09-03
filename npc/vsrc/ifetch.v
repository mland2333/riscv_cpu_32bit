//import "DPI-C" function void ifu_get_inst();
//import "DPI-C" function void idu_decode_inst(input int inst);
module ysyx_20020207_IFU(
  input clock, reset,
  input [31:0] pc_in,
  input pc_ready,

  input  io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  
  output reg io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [31:0] io_master_rdata,

  output reg[31:0]inst, pc_out,
  input fencei, ctrl_valid,
  output inst_valid
//`ifdef CONFIG_BURST
  ,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,
  input io_master_rlast
//`endif
);

always@(posedge clock)begin
  if(pc_ready) pc_out <= pc_in;
end

/*always@(posedge clock)begin
  if(inst_valid)begin
    ifu_get_inst();
    idu_decode_inst(inst);
  end
end*/
reg _inst_valid;
assign inst_valid = _inst_valid;


/*`ifndef CONFIG_ICACHE
reg _arvalid;
assign io_master_arvalid = _arvalid;
reg[31:0] araddr;
assign io_master_araddr = araddr;

//assign io_master_rready = 1;
always@(posedge clock)begin
  if(reset)begin
    inst <= 0;
    _inst_valid <= 0;
  end
  else if(io_master_rvalid && io_master_rready)begin
    io_master_rready <= 0;
    _inst_valid <= 0;
  end
  else if(io_master_rvalid)begin
    inst <= io_master_rdata;
    io_master_rready <= 1;
    _inst_valid <= 1;
  end
  else begin
    _inst_valid <= 0;
    io_master_rready <= 0;
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
`else*/
wire inst_require = pc_ready;
ICACHE icache(
  .reset(reset),
  .clock(clock),
  .inst_require(inst_require),
  .pc(pc_in),
  .fencei(fencei),
  .ctrl_valid(ctrl_valid),
  .inst_valid(_inst_valid),
  .inst(inst),
  .arvalid(io_master_arvalid),
  .arready(io_master_arready),
  .rvalid(io_master_rvalid),
  .rready(io_master_rready),
  .rdata(io_master_rdata),
  .araddr(io_master_araddr)
//`ifdef CONFIG_BURST
    ,
  .arlen(io_master_arlen),
  .arsize(io_master_arsize),
  .arburst(io_master_arburst),
  .rlast(io_master_rlast)
//`endif
);
//`endif

endmodule


