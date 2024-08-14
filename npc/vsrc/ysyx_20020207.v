module ysyx_20020207 #(
    DATA_WIDTH = 32
) (
    input clock,
`ifdef CONFIG_YSYXSOC
    input io_interrupt,
    input io_master_awready,
    output io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [3:0] io_master_awid,
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,

    input io_master_wready,
    output io_master_wvalid,
    output [31:0] io_master_wdata,
    output [3:0] io_master_wstrb,
    output io_master_wlast,

    output io_master_bready,
    input io_master_bvalid,
    input [1:0] io_master_bresp,
    input [3:0] io_master_bid,

    input io_master_arready,
    output io_master_arvalid,
    output [31:0] io_master_araddr,
    output [3:0] io_master_arid,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,

    output io_master_rready,
    input io_master_rvalid,
    input [1:0] io_master_rresp,
    input [31:0] io_master_rdata,
    input io_master_rlast,
    input [3:0] io_master_rid,

    output io_slave_awready,
    input io_slave_awvalid,
    input [31:0] io_slave_awaddr,
    input [3:0] io_slave_awid,
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,
    output io_slave_wready,
    input io_slave_wvalid,
    input [31:0] io_slave_wdata,
    input [3:0] io_slave_wstrb,
    input io_slave_wlast,
    input io_slave_bready,
    output io_slave_bvalid,
    output [1:0] io_slave_bresp,
    output [3:0] io_slave_bid,
    output io_slave_arready,
    input io_slave_arvalid,
    input [31:0] io_slave_araddr,
    input [3:0] io_slave_arid,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
    input io_slave_rready,
    output io_slave_rvalid,
    output [1:0] io_slave_rresp,
    output [31:0] io_slave_rdata,
    output io_slave_rlast,
    output [3:0] io_slave_rid,
`endif
    input reset
);
  import "DPI-C" function void exu_finish_cal();
  wire [DATA_WIDTH-1 : 0] inst;
  reg [DATA_WIDTH-1 : 0] pc, upc;
  wire [31:0] result;
  reg mem_wen, jump, lsu_finish, is_diff_skip;
  wire diff_skip;

  always @(posedge clock) begin
    is_diff_skip <= diff_skip;
  end
`ifdef CONFIG_YSYXSOC
  assign io_master_awid = 'b0,
      io_master_awlen = 'b0,
      io_master_awsize = func,
      io_master_awburst = 'b0,
      io_master_wlast = 'b0,
      io_master_arid = 'b0,
      io_master_arlen = 'b0,
      io_master_arsize    =   (load_ctl == 3'b000 || load_ctl == 3'b100) ? 3'b000 : 
                                (load_ctl == 3'b001 || load_ctl == 3'b101 ? 3'b001 : 3'b010),
      io_master_arburst = 'b0;
`endif

  reg pc_wen;
  wire pc_ready;
  ysyx_20020207_PC #(DATA_WIDTH) mpc (
      .clk (clock),
      .rst (reset),
      .wen (pc_wen),
      .upc (upc),
      .jump(jump),
      .pc  (pc),
      .pc_ready(pc_ready)
  );

  reg diff;
  always @(posedge clock) begin
    if (reset) diff <= 0;
    else begin
      if (pc_wen && ~diff) diff <= 1;
      else diff <= 0;
    end
  end

  always@(posedge clock)begin
    if(reset) pc_wen <= 0;
    else if(lsu_finish)
      pc_wen <= 1;
    else
      pc_wen <= 0;
  end

  wire ifu_arready, ifu_arvalid, ifu_rready;
  wire ifu_rvalid;
  wire [1:0] ifu_rresp;
  wire [31:0] ifu_rdata;
  wire [31:0] ifu_araddr;
  wire inst_valid;
  ysyx_20020207_IFU mifu (
      .clock(clock),
      .reset(reset),
      .pc(pc),
      .pc_ready(pc_ready),
      .inst(inst),
      .io_master_rvalid(ifu_rvalid),
      .io_master_arready(ifu_arready),
      .io_master_rresp(ifu_rresp),
      .io_master_rdata(ifu_rdata),
      .io_master_arvalid(ifu_arvalid),
      .io_master_rready(ifu_rready),
      .io_master_araddr(ifu_araddr),
      .inst_valid(inst_valid)
  );
  always @(posedge clock) begin
    if (inst_valid) exu_finish_cal();
  end
  wire [6:0] op;
  wire [2:0] func;
  wire [4:0] rs1, rs2, rd;
  wire [31:0] imm;
  reg is_exit;
  always @(posedge clock) begin
    is_exit <= inst == 32'b00000000000100000000000001110011;
  end

  ysyx_20020207_IDU midu (
      .inst(inst),
      .op  (op),
      .func(func),
      .rs1 (rs1),
      .rs2 (rs2),
      .rd  (rd),
      .imm (imm)
  );

  wire [DATA_WIDTH-1 : 0] src1, src2, reg_wdata;
  wire reg_wen;
  ysyx_20020207_RegisterFile #(5, DATA_WIDTH) mreg (
      .clk(clock),
      .rst(reset),
      .lsu_finish(lsu_finish),
      .rdata1(src1),
      .raddr1(rs1),
      .rdata2(src2),
      .raddr2(rs2),
      .wdata(reg_wdata),
      .waddr(rd),
      .wen(reg_wen)
  );


  wire [31:0] csr_rdata, csr_wdata;
  wire upc_ctl;
  reg csr_wen;
  wire [2:0] csr_ctl;
  reg [31:0] exu_upc, csr_upc;
  wire [31:0] alu_a, alu_b;
  wire [3:0] wmask;
  wire [3:0] alu_ctl;
  wire [1:0] result_ctl;
  wire mem_ren, alu_sub, alu_sign, exu_jump;
  wire [31:0] alu_result;
  wire [ 2:0] load_ctl;
  ysyx_20020207_EXU #(DATA_WIDTH) mexu (
      .op(op),
      .func(func),
      .src1(src1),
      .src2(src2),
      .imm(imm),
      .pc(pc),
      .csr_rdata(csr_rdata),
      .upc(exu_upc),
      .alu_a(alu_a),
      .alu_b(alu_b),
      .reg_wen(reg_wen),
      .jump(exu_jump),
      .mem_wen(mem_wen),
      .mem_ren(mem_ren),
      .csr_wen(csr_wen),
      .csr_ctl(csr_ctl),
      .alu_ctl(alu_ctl),
      .result_ctl(result_ctl),
      .upc_ctl(upc_ctl),
      .sub(alu_sub),
      .sign(alu_sign),
      .wmask(wmask),
      .load_ctl(load_ctl)
  );

  wire ZF, OF, CF, branch;
  ysyx_20020207_ALU malu (
      .a(alu_a),
      .b(alu_b),
      .alu_ctl(alu_ctl),
      .sub(alu_sub),
      .sign(alu_sign),
      .result(alu_result),
      .ZF(ZF),
      .OF(OF),
      .CF(CF),
      .branch(branch)
  );
  reg [31:0] mem_rdata, mem_wdata;
  wire [31:0] mem_raddr, mem_waddr;
  wire lsu_arvalid, lsu_rready, lsu_awvalid, lsu_wvalid, lsu_bready, lsu_wready;
  wire lsu_rvalid, lsu_bvalid, lsu_awready, lsu_arready;
  wire [31:0] lsu_araddr, lsu_awaddr;
  wire [31:0] lsu_wdata, lsu_rdata;
  wire [3:0] lsu_wstrb;
  wire [1:0] lsu_rresp, lsu_bresp, rresp, bresp;
  assign mem_raddr = alu_result;
  assign mem_waddr = alu_result;
  assign mem_wdata = src2;
  ysyx_20020207_LSU mlsu (
      .clk(clock),
      .rst(reset),
      .inst_rvalid(inst_valid),
      .raddr(mem_raddr),
      .waddr(mem_waddr),
      .wdata(mem_wdata),
      .ren(mem_ren),
      .wen(mem_wen),
      .wmask(wmask),
      .rdata(mem_rdata),
      .lsu_finish(lsu_finish),
      .load_ctl(load_ctl),
      .io_master_rvalid(lsu_rvalid),
      .io_master_arready(lsu_arready),
      .io_master_awready(lsu_awready),
      .io_master_bvalid(lsu_bvalid),
      .io_master_rresp(lsu_rresp),
      .io_master_bresp(lsu_bresp),
      .io_master_rdata(lsu_rdata),
      .io_master_arvalid(lsu_arvalid),
      .io_master_rready(lsu_rready),
      .io_master_awvalid(lsu_awvalid),
      .io_master_wvalid(lsu_wvalid),
      .io_master_wready(lsu_wready),
      .io_master_bready(lsu_bready),
      .io_master_araddr(lsu_araddr),
      .io_master_awaddr(lsu_awaddr),
      .io_master_wdata(lsu_wdata),
      .io_master_wstrb(lsu_wstrb)
  );
  wire [3:0] wstrb;
  wire rvalid, arready, arvalid, rready, awvalid, wvalid, bready, awready, bvalid, wready;
  wire [31:0] araddr, awaddr;
  wire [31:0] wdata, rdata;
  ysyx_20020207_ARBITER marbiter (
      .clk(clock),
      .rst(reset),

      .arvalid1(ifu_arvalid),
      .rready1 (ifu_rready),
      .araddr1 (ifu_araddr),
      .arready1(ifu_arready),
      .rvalid1 (ifu_rvalid),
      .rresp1  (ifu_rresp),
      .rdata1  (ifu_rdata),

      .arvalid2(lsu_arvalid),
      .rready2 (lsu_rready),
      .araddr2 (lsu_araddr),
      .arready2(lsu_arready),
      .rvalid2 (lsu_rvalid),
      .rresp2  (lsu_rresp),
      .rdata2  (lsu_rdata),
      .awvalid2(lsu_awvalid),
      .wvalid2 (lsu_wvalid),
      .bready2 (lsu_bready),
      .wstrb2  (lsu_wstrb),
      .awaddr2 (lsu_awaddr),
      .wdata2  (lsu_wdata),
      .awready2(lsu_awready),
      .wready2 (lsu_wready),
      .bvalid2 (lsu_bvalid),
      .bresp2  (lsu_bresp),

      .arready(arready),
      .rvalid (rvalid),
      .awready(awready),
      .wready (wready),
      .bvalid (bvalid),
      .rresp  (rresp),
      .bresp  (bresp),
      .rdata  (rdata),
      .arvalid(arvalid),
      .rready (rready),
      .awvalid(awvalid),
      .wvalid (wvalid),
      .bready (bready),
      .araddr (araddr),
      .awaddr (awaddr),
      .wdata  (wdata),
      .wstrb  (wstrb)
  );
`ifndef CONFIG_YSYXSOC
  wire sram_arvalid, sram_rready, sram_awvalid, sram_wvalid, sram_bready, sram_wready;
  wire sram_rvalid, sram_bvalid, sram_awready, sram_arready;
  wire [31:0] sram_araddr, sram_awaddr;
  wire [31:0] sram_wdata, sram_rdata;
  wire [3:0] sram_wstrb;
  wire [1:0] sram_rresp, sram_bresp;

  wire uart_arvalid, uart_rready, uart_awvalid, uart_wvalid, uart_bready, uart_wready;
  wire uart_rvalid, uart_bvalid, uart_awready, uart_arready;
  wire [31:0] uart_araddr, uart_awaddr;
  wire [31:0] uart_wdata, uart_rdata;
  wire [3:0] uart_wstrb;
  wire [1:0] uart_rresp, uart_bresp;
`endif
  wire clint_arvalid, clint_rready;
  wire clint_rvalid, clint_arready;
  wire [31:0] clint_araddr;
  wire [31:0] clint_rdata;
  wire [1:0] clint_rresp;
  wire clint_high;

  ysyx_20020207_XBAR mxbar (
      .arvalid  (arvalid),
      .rready   (rready),
      .araddr   (araddr),
      .arready  (arready),
      .rvalid   (rvalid),
      .rresp    (rresp),
      .rdata    (rdata),
      .awvalid  (awvalid),
      .wvalid   (wvalid),
      .bready   (bready),
      .wstrb    (wstrb),
      .awaddr   (awaddr),
      .wdata    (wdata),
      .awready  (awready),
      .wready   (wready),
      .bvalid   (bvalid),
      .bresp    (bresp),
`ifndef CONFIG_YSYXSOC
      .arvalid1 (sram_arvalid),
      .rready1  (sram_rready),
      .araddr1  (sram_araddr),
      .arready1 (sram_arready),
      .rvalid1  (sram_rvalid),
      .rresp1   (sram_rresp),
      .rdata1   (sram_rdata),
      .awvalid1 (sram_awvalid),
      .wvalid1  (sram_wvalid),
      .bready1  (sram_bready),
      .wstrb1   (sram_wstrb),
      .awaddr1  (sram_awaddr),
      .wdata1   (sram_wdata),
      .awready1 (sram_awready),
      .wready1  (sram_wready),
      .bvalid1  (sram_bvalid),
      .bresp1   (sram_bresp),
`else
      .arvalid1 (io_master_arvalid),
      .rready1  (io_master_rready),
      .araddr1  (io_master_araddr),
      .arready1 (io_master_arready),
      .rvalid1  (io_master_rvalid),
      .rresp1   (io_master_rresp),
      .rdata1   (io_master_rdata),
      .awvalid1 (io_master_awvalid),
      .wvalid1  (io_master_wvalid),
      .bready1  (io_master_bready),
      .wstrb1   (io_master_wstrb),
      .awaddr1  (io_master_awaddr),
      .wdata1   (io_master_wdata),
      .awready1 (io_master_awready),
      .wready1  (io_master_wready),
      .bvalid1  (io_master_bvalid),
      .bresp1   (io_master_bresp),
`endif
      .arvalid2 (clint_arvalid),
      .rready2  (clint_rready),
      .araddr2  (clint_araddr),
      .arready2 (clint_arready),
      .rvalid2  (clint_rvalid),
      .rresp2   (clint_rresp),
      .rdata2   (clint_rdata),
      .high     (clint_high),
`ifndef CONFIG_YSYXSOC
      .arvalid3 (uart_arvalid),
      .rready3  (uart_rready),
      .araddr3  (uart_araddr),
      .arready3 (uart_arready),
      .rvalid3  (uart_rvalid),
      .rresp3   (uart_rresp),
      .rdata3   (uart_rdata),
      .awvalid3 (uart_awvalid),
      .wvalid3  (uart_wvalid),
      .bready3  (uart_bready),
      .wstrb3   (uart_wstrb),
      .awaddr3  (uart_awaddr),
      .wdata3   (uart_wdata),
      .awready3 (uart_awready),
      .wready3  (uart_wready),
      .bvalid3  (uart_bvalid),
      .bresp3   (uart_bresp),
`endif
      .diff_skip(diff_skip)
  );

`ifndef CONFIG_YSYXSOC
  SRAM msram (
      .clk(clock),
      .rst(reset),
      .arvalid(sram_arvalid),
      .rready(sram_rready),
      .awvalid(sram_awvalid),
      .wvalid(sram_wvalid),
      .bready(sram_bready),
      .araddr(sram_araddr),
      .awaddr(sram_awaddr),
      .wdata(sram_wdata),
      .wstrb(sram_wstrb),

      .arready(sram_arready),
      .rresp  (sram_rresp),
      .rvalid (sram_rvalid),
      .awready(sram_awready),
      .wready (sram_wready),
      .bvalid (sram_bvalid),
      .bresp  (sram_bresp),
      .rdata  (sram_rdata)
  );

  UART muart (
      .clk(clock),
      .rst(reset),
      .arvalid(uart_arvalid),
      .rready(uart_rready),
      .awvalid(uart_awvalid),
      .wvalid(uart_wvalid),
      .bready(uart_bready),
      .araddr(uart_araddr),
      .awaddr(uart_awaddr),
      .wdata(uart_wdata),
      .wstrb(uart_wstrb),

      .arready(uart_arready),
      .rresp  (uart_rresp),
      .rvalid (uart_rvalid),
      .awready(uart_awready),
      .wready (uart_wready),
      .bvalid (uart_bvalid),
      .bresp  (uart_bresp),
      .rdata  (uart_rdata)
  );
`endif

  ysyx_20020207_CLINT mclint (
      .clk(clock),
      .rst(reset),
      .arvalid(clint_arvalid),
      .rready(clint_rready),
      .araddr(clint_araddr),
      .arready(clint_arready),
      .rresp(clint_rresp),
      .rvalid(clint_rvalid),
      .rdata(clint_rdata),
      .high(clint_high)
  );

  wire [11:0] csr_addr;
  assign csr_addr = imm[11:0];

  ysyx_20020207_CSRU mcsr (
      .clk(clock),
      .wen(csr_wen),
      .csr_ctl(csr_ctl),
      .csr_addr(csr_addr),
      .wdata(csr_wdata),
      .pc(pc),
      .lsu_ready(lsu_finish),
      .rdata(csr_rdata),
      .upc(csr_upc)
  );

  assign jump = exu_jump | branch;
  assign csr_wdata = alu_result;
  assign result = result_ctl == 2'b0 ? alu_result : (result_ctl == 2'b01 ? mem_rdata : csr_rdata);
  assign reg_wdata = result;

  always @(*) begin
    if (upc_ctl == 0) upc = exu_upc;
    else upc = csr_upc;
  end
endmodule
