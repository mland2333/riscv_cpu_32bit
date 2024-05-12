module ysyx_20020207_LSU(
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
  /*output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,*/

  input  io_master_wready,
  output io_master_wvalid,
  output [63:0] io_master_wdata,
  output [7:0] io_master_wstrb,
  //output io_master_wlast,

  output io_master_bready,
  input  io_master_bvalid,
  input  [1:0] io_master_bresp,
  //input  [3:0] io_master_bid,

  input  io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  /*output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,*/

  output io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [63:0] io_master_rdata//,
  //input  io_master_rlast,
  //input  [3:0] io_master_rid,
);
reg arvalid, rready, awvalid, wvalid, bready;

assign  io_master_arvalid   =   arvalid   ,
        io_master_rready    =   rready    ,
        io_master_awvalid   =   awvalid   ,
        io_master_wvalid    =   wvalid    ,
        io_master_bready    =   bready    ,
        io_master_wstrb     =   wstrb     ,
        io_master_araddr    =   raddr     ,
        io_master_awaddr    =   waddr     ,
        io_master_wdata     =   _wdata /*    ,
        io_master_awid      =   'b0       ,
        io_master_awlen     =   'b0       ,
        io_master_awsize    =   'b0       ,
        io_master_awburst   =   'b0       ,
        io_master_wlast     =   'b0       ,
        io_master_arid      =   'b0       ,
        io_master_arlen     =   'b0       ,
        io_master_arsize    =   'b0       ,
        io_master_arburst   =   'b0       */;
reg[7:0] wstrb;
reg[63:0] _wdata;
always@(*)begin
  case(io_master_awaddr[2:0])
    3'b000:begin
      wstrb = wmask;
      _wdata = {32'b0, wdata};
    end
    3'b001:begin
      wstrb = {wmask[6:0], 1'b0};
      _wdata = {24'b0, wdata, 8'b0};
    end
    3'b010:begin
      wstrb = {wmask[5:0], 2'b0};
      _wdata = {16'b0, wdata, 16'b0};
    end
    3'b011:begin
      wstrb = {wmask[4:0], 3'b0};
      _wdata = {8'b0, wdata, 24'b0};
    end
    3'b100:begin
      wstrb = {wmask[3:0], 4'b0};
      _wdata = {wdata, 32'b0};
    end
    3'b101:begin
      wstrb = {wmask[2:0], 5'b0};
      _wdata = {wdata[23:0], 40'b0};
    end
    3'b110:begin
      wstrb = {wmask[1:0], 6'b0};
      _wdata = {wdata[15:0], 48'b0};
    end
    3'b111:begin
      wstrb = {wmask[0], 7'b0};
      _wdata = {wdata[7:0], 56'b0};
    end
  endcase
end

reg[31:0] _rdata;
always@(posedge clk)begin
  if(io_master_rvalid)begin
    case(io_master_araddr[2:0])
      3'b000:begin
        _rdata = io_master_rdata[31:0];
      end
      3'b001:begin
        _rdata = io_master_rdata[39:8];
      end
      3'b010:begin
        _rdata = io_master_rdata[47:16];
      end
      3'b011:begin
        _rdata = io_master_rdata[55:24];
      end
      3'b100:begin
        _rdata = io_master_rdata[63:32];
      end
      3'b101:begin
        _rdata = {8'b0, io_master_rdata[63:40]};
      end
      3'b110:begin
        _rdata = {16'b0, io_master_rdata[63:48]};
      end
      3'b111:begin
        _rdata = {24'b0, io_master_rdata[63:56]};
      end
    endcase
  end
end

reg read_wait_ready, write_wait_ready;
//load
always@(posedge clk)begin
  if(rst)begin
    arvalid <= 0;
    read_wait_ready <= 0;
    rready <= 1;
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
    bready <= 1;
  end
  else begin
    if(!write_wait_ready && wen)begin
        //bready <= 0;
        if(inst_rvalid)begin
          awvalid <= wen;
          wvalid <= wen;
          write_wait_ready <= 1;
        end
      end
    else begin
        if(io_master_bvalid)begin
          awvalid <= 0;
          wvalid <= 0;
          write_wait_ready <= 0;
        end
        /*else if(io_master_awvalid && io_master_awready)begin
          awvalid <= 0;
        end*/
      end
  end
end

always@(posedge clk)begin
  lsu_finish <= (~lsu_finish) && ((inst_rvalid & ~wen &~ren) || wen&io_master_bvalid || ren&io_master_rvalid);
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


