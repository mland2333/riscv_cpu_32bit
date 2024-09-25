//import "DPI-C" function void lsu_get_data();
module ysyx_20020207_LSU (
    input clock,
    input reset,
    input  in_valid,
    output reg out_valid,
`ifdef CONFIG_PIPELINE
    input  out_ready,
    output reg in_ready,
    input jump,
    input need_lsu,
    output lsu_reg_out,
`endif
    input reg_wen_in,
    output reg_wen_out,
    input [4:0] reg_addr_in,
    output [4:0] reg_addr_out,
    input [31:0] addr,
    input [31:0] wdata_in,
    input ren_in,
    input wen_in,
    input [3:0] wmask_in,
    input [2:0] load_ctrl_in,
    output diff_skip,
    output reg [31:0] rdata,
    input io_master_awready,
    output io_master_awvalid,
    output [31:0] io_master_awaddr,
    /*output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  oulsu_reg <= 0;
endtput [1:0] io_master_awbureset,*/

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
  output [1:0] io_master_arbureset,*/

    output io_master_rready,
    input io_master_rvalid,
    input [1:0] io_master_rresp,
    input [31:0] io_master_rdata
    //input  io_master_rlast
    //input  [3:0] io_master_rid,
);
  reg [31:0] waddr, raddr, wdata;
  reg lsu_reg;
  reg wen, ren;
  reg [3:0] wmask;
  reg [2:0] load_ctrl;
  wire valid;
  reg reg_wen;
  reg[4:0] reg_addr;
`ifdef CONFIG_PIPELINE
  always@(posedge clock)begin
    if(reset) out_valid <= 0;
    if(lsu_finish && !out_valid) out_valid <= 1;
    else if(out_valid) out_valid <= 0;
  end

  always @(posedge clock) begin
    if (reset || jump && in_ready) in_ready <= 1;
    else if (in_valid && in_ready) in_ready <= 0;
    else if (!in_ready && out_valid) in_ready <= 1;
  end
  assign valid = in_valid & in_ready & !jump;
`else
  assign valid = in_valid;
  always@(posedge clock)begin
    if(reset) out_valid <= 0;
    if(lsu_finish && !out_valid) out_valid <= 1;
    else if(out_valid) out_valid <= 0;
  end
`endif
  always@(posedge clock)begin
    if(valid) lsu_reg <= 1;
    else if(out_valid) lsu_reg <= 0;
  end
  always @(posedge clock) begin
    if (valid) reg_addr <= reg_addr_in;
  end
  always @(posedge clock) begin
    if (valid) reg_wen <= reg_wen_in;
  end
  always @(posedge clock) begin
    if (valid) waddr <= addr;
  end
  always @(posedge clock) begin
    if (valid) raddr <= addr;
  end
  always @(posedge clock) begin
    if (valid) wen <= wen_in;
    else if (lsu_finish) wen <= 0;
  end
  always @(posedge clock) begin
    if (valid) ren <= ren_in;
    else if (lsu_finish) ren <= 0;
  end
  always @(posedge clock) begin
    if (valid) wmask <= wmask_in;
  end
  always @(posedge clock) begin
    if (valid) wdata <= wdata_in;
  end
  always @(posedge clock) begin
    if (valid) load_ctrl <= load_ctrl_in;
  end
  assign reg_addr_out = reg_addr;
  assign reg_wen_out = reg_wen;
  assign lsu_reg_out = lsu_reg;
  localparam IDLE = 2'b00;
  localparam TRAN1 = 2'b01;
  localparam TRAN2 = 2'b10;
  localparam MID = 2'b11;

wire is_read_uart = raddr[31:12] == 20'h10000;
wire is_read_rtc = raddr[31:16] == 16'h2000;
wire is_read_gpio = raddr[31:4] == 28'h1000200;
wire read_diff_skip = is_read_uart || is_read_rtc || is_read_gpio;

wire is_write_uart = waddr[31:12] == 20'h10000;
wire is_write_gpio = waddr[31:4] == 28'h1000200;
wire write_diff_skip = is_write_uart || is_write_gpio;

assign diff_skip = read_diff_skip || write_diff_skip;

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
        io_master_awbureset   =   'b0       ,
        io_master_wlast     =   'b0       ,
        io_master_arid      =   'b0       ,
        io_master_arlen     =   'b0       ,
        io_master_arsize    =   'b0       ,
        io_master_arbureset   =   'b0       */;
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

  always @(*) begin
    r_tran_nums = 0;
    case (raddr[1:0])
      2'b00: begin
        _rdata = rdata0[31:0];
      end
      2'b01: begin
        if (load_ctrl[1]) begin
          r_tran_nums = 1;
          _rdata = {rdata0[7:0], rdata1[31:8]};
        end else begin
          r_tran_nums = 0;
          _rdata = {8'b0, rdata0[31:8]};
        end
      end
      2'b10: begin
        if (load_ctrl[1]) begin
          r_tran_nums = 1;
          _rdata = {rdata0[15:0], rdata1[31:16]};
        end else begin
          r_tran_nums = 0;
          _rdata = {16'b0, rdata0[31:16]};
        end
      end
      2'b11: begin
        if (load_ctrl[1] || load_ctrl[0]) begin
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
  always @(posedge clock) begin
    if (reset) begin
      arvalid <= 0;
      read_state <= IDLE;
      rready <= 1;
    end else begin
      case (read_state)
        IDLE: begin
          io_master_araddr <= 0;
          if (ren) begin
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
  always @(posedge clock) begin
    if (reset) begin
      awvalid <= 0;
      write_state <= IDLE;
      bready <= 1;
    end else begin
      case (write_state)
        IDLE: begin
          io_master_awaddr <= 0;
          if (wen) begin
            awvalid <= 1;
            wvalid <= 1;
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

  wire lsu_finish = io_master_bvalid&&(write_state==TRAN1)
                      || io_master_rvalid&&(read_state ==TRAN1);

  always @(*) begin
    case (load_ctrl)
      3'b000:  rdata = {{24{_rdata[7]}}, _rdata[7:0]};
      3'b001:  rdata = {{16{_rdata[15]}}, _rdata[15:0]};
      3'b010:  rdata = _rdata;
      3'b100:  rdata = {24'b0, _rdata[7:0]};
      3'b101:  rdata = {16'b0, _rdata[15:0]};
      default: rdata = _rdata;
    endcase
  end
endmodule


