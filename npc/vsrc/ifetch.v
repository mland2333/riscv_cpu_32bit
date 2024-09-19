//import "DPI-C" function void ifu_get_inst();
//import "DPI-C" function void idu_decode_inst(input int inst);
module ysyx_20020207_IFU (
    input clock,
    input reset,
    input [31:0] pc_in,
    output [31:0] pc_out,
    input in_valid,
    output reg out_valid,
`ifdef CONFIG_PIPELINE
    input out_ready,
    output reg in_ready,
    input jump,
`endif
    input io_master_arready,
    output io_master_arvalid,
    output [31:0] io_master_araddr,

    output reg io_master_rready,
    input io_master_rvalid,
    input [1:0] io_master_rresp,
    input [31:0] io_master_rdata,

    output reg [31:0] inst,
    input fencei
    //`ifdef CONFIG_BURST
    , output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,
    input io_master_rlast
    //`endif
);

  reg [31:0] pc;
  assign pc_out = pc;
  wire inst_valid;
`ifdef CONFIG_PIPELINE
  reg refresh;
  always @(posedge clock) begin
    if (reset) refresh <= 0;
    else if (jump) refresh <= 1;
    else if (inst_valid) refresh <= 0;
  end
  always @(posedge clock) begin
    if (reset) in_ready <= 1;
    else if (in_valid && in_ready) in_ready <= 0;
    else if (!in_ready && inst_valid && out_ready) in_ready <= 1;
  end

  always @(posedge clock) begin
    if (reset) pc <= 0;
    else if (in_valid && in_ready) pc <= pc_in;
  end
  assign out_valid = !refresh && inst_valid;
  wire inst_require = in_valid && in_ready;
`else

  always @(posedge clock) begin
    if (in_valid) pc <= pc_in;
  end
  wire inst_require = in_valid;
  assign out_valid = inst_valid;
`endif

  /*always@(posedge clock)begin
  if(inst_valid)begin
    ifu_get_inst();
    idu_decode_inst(inst);
  end
end*/

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
  ICACHE icache (
      .reset(reset),
      .clock(clock),
      .require(inst_require),
      .pc(pc_in),
      .fencei(fencei),
`ifdef CONFIG_PIPELINE
      .out_ready(out_ready),
`endif
      .inst_valid(inst_valid),
      .inst(inst),
      .arvalid(io_master_arvalid),
      .arready(io_master_arready),
      .rvalid(io_master_rvalid),
      .rready(io_master_rready),
      .rdata(io_master_rdata),
      .araddr(io_master_araddr)
      //`ifdef CONFIG_BURST
      , .arlen(io_master_arlen),
      .arsize(io_master_arsize),
      .arburst(io_master_arburst),
      .rlast(io_master_rlast)
      //`endif
  );
  //`endif

endmodule


