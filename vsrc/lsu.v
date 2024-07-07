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
  input  [63:0] io_master_rdata
  //input  io_master_rlast
  //input  [3:0] io_master_rid,
);
localparam IDLE = 2'b00;
localparam TRAN1 = 2'b01;
localparam TRAN2 = 2'b10;
localparam MID = 2'b11;

wire is_read_sram = raddr >= 32'h0f000000 && raddr < 32'h0f002000;
wire is_write_sram = waddr >= 32'h0f000000 && waddr < 32'h0f002000;

wire is_read_psram = raddr >= 32'h80000000 && raddr < 32'ha0000000;
wire is_read_sdram = raddr >= 32'ha0000000 && raddr < 32'hc0000000;

reg arvalid, rready, awvalid, wvalid, bready;
reg[7:0] _wstrb;
assign  io_master_arvalid   =   arvalid   ,
        io_master_rready    =   rready    ,
        io_master_awvalid   =   awvalid   ,
        io_master_wvalid    =   wvalid    ,
        io_master_bready    =   bready    ,
        io_master_wstrb     =   _wstrb     ,
        //io_master_araddr    =   {raddr[31:3], 3'b0}     ,
        //io_master_awaddr    =   {waddr[31:3], 3'b0}     ,
        io_master_wdata     =   _wdata_sram/*    ,
        io_master_awid      =   'b0       ,
        io_master_awlen     =   'b0       ,
        io_master_awsize    =   'b0       ,
        io_master_awburst   =   'b0       ,
        io_master_wlast     =   'b0       ,
        io_master_arid      =   'b0       ,
        io_master_arlen     =   'b0       ,
        io_master_arsize    =   'b0       ,
        io_master_arburst   =   'b0       */;
reg[7:0] wstrb, wstrb1;
reg[63:0] _wdata_sram;
reg w_tran_nums;
always@(*)begin
  w_tran_nums = 0;
  wstrb1 = 0;
  case(waddr[2:0])
    3'b000:begin
      wstrb = wmask;
      _wdata_sram = {32'b0, wdata};
    end
    3'b001:begin
      wstrb = {wmask[6:0], 1'b0};
      _wdata_sram = {24'b0, wdata, 8'b0};
    end
    3'b010:begin
      wstrb = {wmask[5:0], 2'b0};
      _wdata_sram = {16'b0, wdata, 16'b0};
    end
    3'b011:begin
      wstrb = {wmask[4:0], 3'b0};
      _wdata_sram = {8'b0, wdata, 24'b0};
    end
    3'b100:begin
      wstrb = {wmask[3:0], 4'b0};
      _wdata_sram = {wdata, 32'b0};
    end
    3'b101:begin
      wstrb = {wmask[2:0], 5'b0};
      _wdata_sram = {wdata[23:0], 32'b0, wdata[31:24]};
      if(wmask[3])begin
        w_tran_nums = 1;
        wstrb1 = {3'b0, wmask[7:3]};
      end
    end
    3'b110:begin
      wstrb = {wmask[1:0], 6'b0};
      _wdata_sram = {wdata[15:0], 32'b0, wdata[31:16]};
      if(wmask[3])begin
        w_tran_nums = 1;
        wstrb1 = {2'b0, wmask[7:2]};
      end
    end
    3'b111:begin
      wstrb = {wmask[0], 7'b0 };
      _wdata_sram = {wdata[7:0], 32'b0, wdata[31:8]};
      if(wmask[1])begin
        w_tran_nums = 1;
        wstrb1 = {1'b0, wmask[7:1]};
      end
    end
  endcase
end

reg[31:0] _rdata, _rdata_sram, _rdata_psram;
reg[63:0] _rdata0, _rdata1;
reg r_tran_nums;
always@(*)begin
  r_tran_nums = 0;
  case(raddr[2:0])
    3'b000:begin
      _rdata_sram = _rdata0[31:0];
      _rdata_psram = _rdata0[31:0];
    end
    3'b001:begin
      _rdata_sram = _rdata0[39:8];
      _rdata_psram = {8'b0, _rdata0[31:8]};
    end
    3'b010:begin
      _rdata_sram = _rdata0[47:16];
      _rdata_psram = {16'b0, _rdata0[31:16]};
    end
    3'b011:begin
      _rdata_sram = _rdata0[55:24];
      _rdata_psram = {24'b0, _rdata0[31:24]};
    end
    3'b100:begin
      _rdata_psram = _rdata0[31:0];
      _rdata_sram = _rdata0[63:32];
    end
    3'b101:begin
      _rdata_psram = {8'b0, _rdata0[31:8]};
      if(load_ctl[1])begin
        r_tran_nums = 1;
        _rdata_sram = {_rdata0[7:0], _rdata1[63:40]};
      end
      else begin
        r_tran_nums = 0;
        _rdata_sram = {8'b0, _rdata0[63:40]};
      end
    end
    3'b110:begin
      _rdata_psram = {16'b0, _rdata0[31:16]};
      if(load_ctl[1])begin
        r_tran_nums = 1;
        _rdata_sram = {_rdata0[15:0], _rdata1[63:48]};
      end
      else begin
        r_tran_nums = 0;
        _rdata_sram = {16'b0, _rdata0[63:48]};
      end
    end
    3'b111:begin
      _rdata_psram = {24'b0, _rdata0[31:24]};
      if(load_ctl[1] || load_ctl[0])begin
        r_tran_nums = 1;
        _rdata_sram = {_rdata0[23:0], _rdata1[63:56]};
      end
      else begin
        r_tran_nums = 0;
        _rdata_sram = {24'b0, _rdata0[63:56]};
      end
    end
  endcase
end

reg read_wait_ready, write_wait_ready;
reg[1:0] read_state;
//load
always@(posedge clk)begin
  if(rst)begin
    arvalid <= 0;
    read_state <= IDLE;
    rready <= 1;
  end
  else begin
    case(read_state)
      IDLE:begin
        if(ren && inst_rvalid)begin
          arvalid <= 1;
          io_master_araddr <= raddr;
          if(r_tran_nums == 1 && is_read_sram)
            read_state <= TRAN2;
          else 
            read_state <= TRAN1;
        end
      end
      TRAN1:begin
        if(io_master_arvalid && io_master_arready)
          arvalid <= 0;
        if(io_master_rvalid)begin
          arvalid <= 0;
          read_state <= IDLE;
          _rdata0 <= io_master_rdata;
        end
      end
      TRAN2:begin
        if(io_master_arvalid && io_master_arready)
          arvalid <= 0;
        if(io_master_rvalid)begin
          arvalid <= 0;
          read_state <= MID;
          _rdata1 <= io_master_rdata;
        end
      end
      MID:begin
          io_master_araddr <= io_master_araddr + 8;
          arvalid <= 1;
          read_state <= TRAN1;
      end
    endcase
  end
end
//store
reg[1:0] write_state;
always@(posedge clk)begin
  if(rst)begin
    awvalid <= 0;
    write_state <= IDLE;
    bready <= 1;
  end
  else begin
    case(write_state)
      IDLE:begin
        if(wen && inst_rvalid)begin
          awvalid <= wen;
          wvalid <= wen;
          io_master_awaddr <= waddr;
          _wstrb <= wstrb;
          if(is_write_sram)begin
            //_wstrb <= wstrb;
            if(w_tran_nums == 1)
              write_state <= TRAN2;
            else
              write_state <= TRAN1;
          end
          else begin
            //_wstrb <= wmask;
            write_state <= TRAN1;
          end
        end
      end
      TRAN1:begin
        if(io_master_awvalid && io_master_awready)
          awvalid <= 0;
        if(io_master_wvalid && io_master_wready)
          wvalid <= 0;
        if(io_master_bvalid)begin
          awvalid <= 0;
          wvalid <= 0;
          write_state <= IDLE;
        end
      end
      TRAN2:begin
        if(io_master_awvalid && io_master_awready)
          awvalid <= 0;
        if(io_master_wvalid && io_master_wready)
          wvalid <= 0;
        if(io_master_bvalid)begin
          awvalid <= 0;
          wvalid <= 0;
          write_state <= MID;
        end
      end
      MID:begin
        io_master_awaddr <= io_master_awaddr + 8;
        awvalid <= 1;
        wvalid <= 1;
        _wstrb <= wstrb1;
        write_state <= TRAN1;
      end
    endcase
  end
end

always@(posedge clk)begin
  lsu_finish <= (~lsu_finish) && ((inst_rvalid & ~wen &~ren)
                || wen&&io_master_bvalid&&(write_state==TRAN1)
                || ren&&io_master_rvalid&&(read_state ==TRAN1));
end

assign _rdata = is_read_sram ? _rdata_sram : (is_read_psram||is_read_sdram ? _rdata_psram : _rdata0[31:0]);

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


