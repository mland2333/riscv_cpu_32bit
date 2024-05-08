module LSU(
  input clk, rst, inst_rvalid,
  input[31:0] raddr, waddr, wdata,
  input ren, wen,
  input[7:0] wmask,
  input[2:0] load_ctl,
  output reg[31:0] rdata,
  output lsu_finish,

  input  io_master_awready,
  output io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,

  input  io_master_wready,
  output io_master_wvalid,
  output [63:0] io_master_wdata,
  output [7:0] io_master_wstrb,
  output io_master_wlast,

  output io_master_bready,
  input  io_master_bvalid,
  input  [1:0] io_master_bresp,
  input  [3:0] io_master_bid,

  input  io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,

  output io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [63:0] io_master_rdata,
  input  io_master_rlast,
  input  [3:0] io_master_rid,

  input lsu_rvalid, lsu_arready, lsu_awready, lsu_wready, lsu_bvalid, 
  input[1:0] rresp, bresp,
  input [31:0] lsu_rdata,
  output reg lsu_arvalid, lsu_rready, lsu_awvalid, lsu_wvalid, lsu_bready, 
  output[31:0] lsu_araddr, lsu_awaddr, lsu_wdata ,
  output[7:0] lsu_wstrb
);
reg arvalid, rready, awvalid, wvalid, bready;

assign  io_master_arvalid   =   arvalid   ,
        io_master_rready    =   rready    ,
        io_master_awvalid   =   awvalid   ,
        io_master_wvalid    =   wvalid    ,
        io_master_bready    =   bready    ,
        io_master_wstrb     =   wmask     ,
        io_master_araddr    =   raddr     ,
        io_master_awaddr    =   waddr     ,
        io_master_wdata     =   {32'b0, wdata}     ,
        io_master_awid      =   'b0       ,
        io_master_awlen     =   'b0       ,
        io_master_awsize    =   'b0       ,
        io_master_awburst   =   'b0       ,
        io_master_wlast     =   'b0       ,
        io_master_arid      =   'b0       ,
        io_master_arlen     =   'b0       ,
        io_master_arsize    =   'b0       ,
        io_master_arburst   =   'b0       ;

reg[31:0] _rdata;
always@(posedge clk)begin
  if(io_master_rvalid)begin
    _rdata <= io_master_rdata[31:0];
  end
end

reg read_wait_ready, write_wait_ready;
//load
always@(posedge clk)begin
  if(rst)begin
    arvalid <= 0;
    read_wait_ready <= 0;
  end
  else begin
    if(!read_wait_ready && ren)begin
        if(inst_rvalid)begin
          arvalid <= ren;
          read_wait_ready <= 1;
        end
    end
    else begin
        if(io_master_arvalid && io_master_arready)begin
          arvalid <= 0;
          read_wait_ready <= 0;
        end
    end
  end
end

//store
always@(posedge clk)begin
  if(rst)begin
    awvalid <= 0;
    write_wait_ready <= 0;
    bready <= 0;
  end
  else begin
    if(!write_wait_ready && wen)begin
        bready <= 0;
        if(inst_rvalid)begin
          awvalid <= wen;
          wvalid <= wen;
          write_wait_ready <= 1;
        end
      end
    else begin
        if(io_master_wready)begin
          awvalid <= 0;
          wvalid <= 0;
          bready <= 1;
          write_wait_ready <= 0;
        end
        else if(io_master_awvalid && io_master_awready)begin
          awvalid <= 0;
        end
        else begin
          bready <= 0;
        end
      end
  end
end

always@(posedge clk)begin
  io_master_finish <= (~io_master_finish) && ((inst_rvalid & ~wen &~ren) || wen&io_master_wready || ren&io_master_rvalid);
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


