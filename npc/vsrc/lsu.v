//import "DPI-C" function void lsu_get_data();
module ysyx_20020207_LSU (
    input clk,
    rst,
    ctrl_valid,
    alu_valid,
    input [31:0] raddr,
    waddr,
    wdata,
    input ren,
    wen,
    input [3:0] wmask,
    input [2:0] load_ctrl,
    output reg [31:0] rdata,
    output lsu_finish,
    
  `ifdef CONFIG_PIPELINE
    input in_valid, out_ready,
    output out_valid, in_ready,
  `endif

    input io_master_awready,
    output io_master_awvalid,
    output [31:0] io_master_awaddr,
    /*output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,*/

    input io_master_wready,
    output io_master_wvalid,
    output [31:0] io_master_wdata,
    output [3:0] io_master_wstrb,
    //output io_master_wlast,

    output io_master_bready,
    input io_master_bvalid,
    input [1:0] io_master_bresp,
    //input  [3:0] io_master_bid,

    input io_master_arready,
    output io_master_arvalid,
    output [31:0] io_master_araddr,
    /*output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,*/

    output io_master_rready,
    input io_master_rvalid,
    input [1:0] io_master_rresp,
    input [31:0] io_master_rdata
    //input  io_master_rlast
    //input  [3:0] io_master_rid,
);
  localparam IDLE = 2'b00;
  localparam TRAN1 = 2'b01;
  localparam TRAN2 = 2'b10;
  localparam MID = 2'b11;

  reg arvalid, rready, awvalid, wvalid, bready;
  reg [3:0] _wstrb;
  assign io_master_arvalid = arvalid,
      io_master_rready = rready,
      io_master_awvalid = awvalid,
      io_master_wvalid = wvalid,
      io_master_bready = bready,
      io_master_wstrb = _wstrb,
      //io_master_araddr    =   {raddr[31:3], 3'b0}     ,
      //io_master_awaddr    =   {waddr[31:3], 3'b0}     ,
      io_master_wdata = _wdata  /*    ,
        io_master_awid      =   'b0       ,
        io_master_awlen     =   'b0       ,
        io_master_awsize    =   'b0       ,
        io_master_awburst   =   'b0       ,
        io_master_wlast     =   'b0       ,
        io_master_arid      =   'b0       ,
        io_master_arlen     =   'b0       ,
        io_master_arsize    =   'b0       ,
        io_master_arburst   =   'b0       */;
  reg [3:0] wstrb, wstrb1;
  reg [31:0] _wdata;
  reg w_tran_nums;
  always @(*) begin
    w_tran_nums = 0;
    wstrb1 = 0;
    case (waddr[1:0])
      2'b00: begin
        wstrb  = wmask;
        _wdata = wdata;
      end
      2'b01: begin
        wstrb  = {wmask[2:0], 1'b0};
        _wdata = {wdata[23:0], wdata[31:24]};
        if (wmask[3]) begin
          w_tran_nums = 1;
          wstrb1 = 4'b0001;
        end
      end
      2'b10: begin
        wstrb  = {wmask[1:0], 2'b0};
        _wdata = {wdata[15:0], wdata[31:16]};
        if (wmask[3]) begin
          w_tran_nums = 1;
          wstrb1 = 4'b0011;
        end
      end
      2'b11: begin
        wstrb  = {wmask[0], 3'b0};
        _wdata = {wdata[7:0], wdata[31:8]};
        if (wmask[1]) begin
          w_tran_nums = 1;
          wstrb1 = {1'b0, wmask[3:1]};
        end
      end
    endcase
  end

  reg [31:0] _rdata;
  reg [31:0] rdata0, rdata1;
  reg r_tran_nums;
  reg[2:0] _load_ctrl;
  always@(posedge clk)begin
    if(rst) _load_ctrl <= 0;
    else if(ctrl_valid) _load_ctrl <= load_ctrl;
  end

  always @(*) begin
    r_tran_nums = 0;
    case (raddr[1:0])
      2'b00: begin
        _rdata = rdata0[31:0];
      end
      2'b01: begin
        if (_load_ctrl[1]) begin
          r_tran_nums = 1;
          _rdata = {rdata0[7:0], rdata1[31:8]};
        end else begin
          r_tran_nums = 0;
          _rdata = {8'b0, rdata0[31:8]};
        end
      end
      2'b10: begin
        if (_load_ctrl[1]) begin
          r_tran_nums = 1;
          _rdata = {rdata0[15:0], rdata1[31:16]};
        end else begin
          r_tran_nums = 0;
          _rdata = {16'b0, rdata0[31:16]};
        end
      end
      2'b11: begin
        if (_load_ctrl[1] || _load_ctrl[0]) begin
          r_tran_nums = 1;
          _rdata = {rdata0[23:0], rdata1[31:24]};
        end else begin
          r_tran_nums = 0;
          _rdata = {24'b0, rdata0[31:24]};
        end
      end
    endcase
  end

  reg read_wait_ready, write_wait_ready;
  reg [1:0] read_state;
  //load
  always @(posedge clk) begin
    if (rst) begin
      arvalid <= 0;
      read_state <= IDLE;
      rready <= 1;
    end else begin
      case (read_state)
        IDLE: begin
          io_master_araddr <= 0;
          if (ren && alu_valid) begin
            arvalid <= 1;
            io_master_araddr <= raddr;
            if (r_tran_nums == 1) read_state <= TRAN2;
            else read_state <= TRAN1;
          end
        end
        TRAN1: begin
          if (io_master_arvalid && io_master_arready) arvalid <= 0;
          if (io_master_rvalid) begin
            arvalid <= 0;
            read_state <= IDLE;
            rdata0 <= io_master_rdata;
            //lsu_get_data();
          end
        end
        TRAN2: begin
          if (io_master_arvalid && io_master_arready) arvalid <= 0;
          if (io_master_rvalid) begin
            arvalid <= 0;
            read_state <= MID;
            rdata1 <= io_master_rdata;
          end
        end
        MID: begin
          io_master_araddr <= io_master_araddr + 4;
          arvalid <= 1;
          read_state <= TRAN1;
        end
      endcase
    end
  end
  //store
  reg [1:0] write_state;
  always @(posedge clk) begin
    if (rst) begin
      awvalid <= 0;
      write_state <= IDLE;
      bready <= 1;
    end else begin
      case (write_state)
        IDLE: begin
          io_master_awaddr <= 0;
          if (wen && alu_valid) begin
            awvalid <= wen;
            wvalid <= wen;
            io_master_awaddr <= waddr;
            _wstrb <= wstrb;
            if (w_tran_nums == 1) write_state <= TRAN2;
            else write_state <= TRAN1;
          end
        end
        TRAN1: begin
          if (io_master_awvalid && io_master_awready) awvalid <= 0;
          if (io_master_wvalid && io_master_wready) wvalid <= 0;
          if (io_master_bvalid) begin
            awvalid <= 0;
            wvalid <= 0;
            write_state <= IDLE;
          end
        end
        TRAN2: begin
          if (io_master_awvalid && io_master_awready) awvalid <= 0;
          if (io_master_wvalid && io_master_wready) wvalid <= 0;
          if (io_master_bvalid) begin
            awvalid <= 0;
            wvalid <= 0;
            write_state <= MID;
          end
        end
        MID: begin
          io_master_awaddr <= io_master_awaddr + 4;
          awvalid <= 1;
          wvalid <= 1;
          _wstrb <= wstrb1;
          write_state <= TRAN1;
        end
      endcase
    end
  end

  always @(posedge clk) begin
    lsu_finish <= (~lsu_finish) && ((alu_valid & ~wen &~ren)
                || wen&&io_master_bvalid&&(write_state==TRAN1)
                || ren&&io_master_rvalid&&(read_state ==TRAN1));
  end

  always @(*) begin
    case (_load_ctrl)
      3'b000:  rdata = {{24{_rdata[7]}}, _rdata[7:0]};
      3'b001:  rdata = {{16{_rdata[15]}}, _rdata[15:0]};
      3'b010:  rdata = _rdata;
      3'b100:  rdata = {24'b0, _rdata[7:0]};
      3'b101:  rdata = {16'b0, _rdata[15:0]};
      default: rdata = _rdata;
    endcase
  end
endmodule
 

