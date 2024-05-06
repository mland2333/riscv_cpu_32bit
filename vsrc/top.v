module top #(DATA_WIDTH = 32)(
    input clk,rst,read_valid,
    output [DATA_WIDTH-1 : 0] inst,
    output reg[DATA_WIDTH-1 : 0] pc, upc,
    output [31:0] result,
    output reg exit, mem_wen, jump, lsu_finish, diff_skip
);

    wire pc_wen;

    PC #(DATA_WIDTH) mpc(
      .clk(clk),
      .rst(rst),
      .wen(pc_wen),
      .upc(upc),
      .jump(jump),
      .pc(pc)
    );
    
    wire ifu_arready, ifu_ok, ifu_request, ifu_arvalid, ifu_rready;
    wire ifu_rvalid;
    wire[1:0] ifu_rresp;
    wire[31:0] ifu_rdata, ifu_araddr;
    wire inst_valid;
    IFU mifu(
      .clk(clk),
      .rst(rst),
      .lsu_finish(lsu_finish),
      .pc(pc),
      .inst(inst),
      .ifu_rvalid(ifu_rvalid),
      .ifu_arready(ifu_arready),
      .ifu_rresp(ifu_rresp),
      .ifu_rdata(ifu_rdata),
      .ifu_arvalid(ifu_arvalid),
      .ifu_rready(ifu_rready),
      .ifu_araddr(ifu_araddr),
      .pc_wen(pc_wen),
      .inst_valid(inst_valid)
    );
    wire [6:0]op;
    wire [2:0]func;
    wire [4:0]rs1, rs2, rd;
    wire [31:0] imm;

    IDU midu(
      .inst(inst),
      .op(op),
      .func(func),
      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .imm(imm)
    );

    wire[DATA_WIDTH-1 : 0] src1, src2, reg_wdata;
    wire reg_wen;
    RegisterFile #(5, DATA_WIDTH) mreg(
      .clk(clk),
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
    reg[31:0] exu_upc, csr_upc;
    wire[31:0] alu_a, alu_b;
    wire[7:0] wmask;
    wire[3:0] alu_ctl;
    wire[1:0] result_ctl;
    wire mem_ren, alu_sub, alu_sign, exu_jump;
    wire[31:0] alu_result;
    wire[2:0] load_ctl;
    EXU #(DATA_WIDTH) mexu(
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
    ALU malu(
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
    reg[31:0] mem_rdata, mem_wdata;
    wire[31:0] mem_raddr, mem_waddr;
    wire lsu_arvalid, lsu_rready, lsu_awvalid, lsu_wvalid, lsu_bready, lsu_wready;
    wire lsu_rvalid, lsu_bvalid, lsu_awready, lsu_arready; 
    wire [31:0] lsu_araddr, lsu_awaddr, lsu_wdata, lsu_rdata;
    wire[7:0] lsu_wstrb;
    wire[1:0] lsu_rresp, lsu_bresp, rresp, bresp;
    assign mem_raddr = alu_result;
    assign mem_waddr = alu_result;
    assign mem_wdata = src2;
    LSU mlsu(
      .clk(clk),
      .rst(rst),
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
      .lsu_rvalid(lsu_rvalid),
      .lsu_arready(lsu_arready),
      .lsu_awready(lsu_awready),
      .lsu_bvalid(lsu_bvalid),
      .rresp(lsu_rresp),
      .bresp(lsu_bresp),
      .lsu_rdata(lsu_rdata),
      .lsu_arvalid(lsu_arvalid),
      .lsu_rready(lsu_rready),
      .lsu_awvalid(lsu_awvalid),
      .lsu_wvalid(lsu_wvalid),
      .lsu_wready(lsu_wready),
      .lsu_bready(lsu_bready),
      .lsu_araddr(lsu_araddr),
      .lsu_awaddr(lsu_awaddr),
      .lsu_wdata(lsu_wdata),
      .lsu_wstrb(lsu_wstrb)
    );
    wire[7:0] wstrb;
    wire rvalid, arready, arvalid, rready, awvalid, wvalid, bready, awready, bvalid, wready;
    wire[31:0] araddr, awaddr, wdata, rdata;
    wire ifu_awready, ifu_wready, ifu_bvalid;
    wire [1:0] ifu_bresp;
    ARBITER marbiter(
      .clk(clk),
      .rst(rst),

      .arvalid1(ifu_arvalid),
      .rready1(ifu_rready),
      .araddr1(ifu_araddr),
      .arready1(ifu_arready),
      .rvalid1(ifu_rvalid),
      .rresp1(ifu_rresp),
      .rdata1(ifu_rdata),
      .awvalid1(0),
      .wvalid1(0),
      .bready1(0),
      .wstrb1(0),
      .awaddr1(0),
      .wdata1(0),
      .awready1(ifu_awready),
      .wready1(ifu_wready),
      .bvalid1(ifu_bvalid),
      .bresp1(ifu_bresp),

      .arvalid2(lsu_arvalid),
      .rready2(lsu_rready),
      .araddr2(lsu_araddr),
      .arready2(lsu_arready),
      .rvalid2(lsu_rvalid),
      .rresp2(lsu_rresp),
      .rdata2(lsu_rdata),
      .awvalid2(lsu_awvalid),
      .wvalid2(lsu_wvalid),
      .bready2(lsu_bready),
      .wstrb2(lsu_wstrb),
      .awaddr2(lsu_awaddr),
      .wdata2(lsu_wdata),
      .awready2(lsu_awready),
      .wready2(lsu_wready),
      .bvalid2(lsu_bvalid),
      .bresp2(lsu_bresp),

      .arready(arready),
      .rvalid(rvalid),
      .awready(awready),
      .wready(wready),
      .bvalid(bvalid),
      .rresp(rresp),
      .bresp(bresp),
      .rdata(rdata),
      .arvalid(arvalid),
      .rready(rready),
      .awvalid(awvalid),
      .wvalid(wvalid),
      .bready(bready),
      .araddr(araddr),
      .awaddr(awaddr),
      .wdata(wdata),
      .wstrb(wstrb)
    );
    wire sram_arvalid, sram_rready, sram_awvalid, sram_wvalid, sram_bready, sram_wready;
    wire sram_rvalid, sram_bvalid, sram_awready, sram_arready; 
    wire [31:0] sram_araddr, sram_awaddr, sram_wdata, sram_rdata;
    wire[7:0] sram_wstrb;
    wire[1:0] sram_rresp, sram_bresp;

    wire uart_arvalid, uart_rready, uart_awvalid, uart_wvalid, uart_bready, uart_wready;
    wire uart_rvalid, uart_bvalid, uart_awready, uart_arready; 
    wire [31:0] uart_araddr, uart_awaddr, uart_wdata, uart_rdata;
    wire[7:0] uart_wstrb;
    wire[1:0] uart_rresp, uart_bresp;

    wire clint_arvalid, clint_rready, clint_awvalid, clint_wvalid, clint_bready, clint_wready;
    wire clint_rvalid, clint_bvalid, clint_awready, clint_arready; 
    wire [31:0] clint_araddr, clint_awaddr, clint_wdata, clint_rdata;
    wire[7:0] clint_wstrb;
    wire[1:0] clint_rresp, clint_bresp;
    wire clint_high;

    XBAR mxbar(
      .arvalid(arvalid),
      .rready(rready),
      .araddr(araddr),
      .arready(arready),
      .rvalid(rvalid),
      .rresp(rresp),
      .rdata(rdata),
      .awvalid(awvalid),
      .wvalid(wvalid),
      .bready(bready),
      .wstrb(wstrb),
      .awaddr(awaddr),
      .wdata(wdata),
      .awready(awready),
      .wready(wready),
      .bvalid(bvalid),
      .bresp(bresp),

      .arvalid1(sram_arvalid),
      .rready1(sram_rready),
      .araddr1(sram_araddr),
      .arready1(sram_arready),
      .rvalid1(sram_rvalid),
      .rresp1(sram_rresp),
      .rdata1(sram_rdata),
      .awvalid1(sram_awvalid),
      .wvalid1(sram_wvalid),
      .bready1(sram_bready),
      .wstrb1(sram_wstrb),
      .awaddr1(sram_awaddr),
      .wdata1(sram_wdata),
      .awready1(sram_awready),
      .wready1(sram_wready),
      .bvalid1(sram_bvalid),
      .bresp1(sram_bresp),

      .arvalid2(uart_arvalid),
      .rready2(uart_rready),
      .araddr2(uart_araddr),
      .arready2(uart_arready),
      .rvalid2(uart_rvalid),
      .rresp2(uart_rresp),
      .rdata2(uart_rdata),
      .awvalid2(uart_awvalid),
      .wvalid2(uart_wvalid),
      .bready2(uart_bready),
      .wstrb2(uart_wstrb),
      .awaddr2(uart_awaddr),
      .wdata2(uart_wdata),
      .awready2(uart_awready),
      .wready2(uart_wready),
      .bvalid2(uart_bvalid),
      .bresp2(uart_bresp),

      .arvalid3(clint_arvalid),
      .rready3(clint_rready),
      .araddr3(clint_araddr),
      .arready3(clint_arready),
      .rvalid3(clint_rvalid),
      .rresp3(clint_rresp),
      .rdata3(clint_rdata),
      .awvalid3(clint_awvalid),
      .wvalid3(clint_wvalid),
      .bready3(clint_bready),
      .wstrb3(clint_wstrb),
      .awaddr3(clint_awaddr),
      .wdata3(clint_wdata),
      .awready3(clint_awready),
      .wready3(clint_wready),
      .bvalid3(clint_bvalid),
      .bresp3(clint_bresp),
      .high(clint_high),

      .diff_skip(diff_skip)
    );


    SRAM msram(
      .clk(clk),
      .rst(rst),
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
      .rresp(sram_rresp),
      .rvalid(sram_rvalid),
      .awready(sram_awready),
      .wready(sram_wready),
      .bvalid(sram_bvalid),
      .bresp(sram_bresp),
      .rdata(sram_rdata)
    );
    
    UART muart(
      .clk(clk),
      .rst(rst),
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
      .rresp(uart_rresp),
      .rvalid(uart_rvalid),
      .awready(uart_awready),
      .wready(uart_wready),
      .bvalid(uart_bvalid),
      .bresp(uart_bresp),
      .rdata(uart_rdata)
    );
    CLINT mclint(
      .clk(clk),
      .rst(rst),
      .arvalid(clint_arvalid),
      .rready(clint_rready),
      .awvalid(clint_awvalid),
      .wvalid(clint_wvalid),
      .bready(clint_bready),
      .araddr(clint_araddr),
      .awaddr(clint_awaddr),
      .wdata(clint_wdata),
      .wstrb(clint_wstrb),

      .arready(clint_arready),
      .rresp(clint_rresp),
      .rvalid(clint_rvalid),
      .awready(clint_awready),
      .wready(clint_wready),
      .bvalid(clint_bvalid),
      .bresp(clint_bresp),
      .rdata(clint_rdata),

      .high(clint_high)
    );

    wire[11:0] csr_addr;
    assign csr_addr = imm[11:0];

    CSRU mcsr(
      .clk(clk),
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
    assign result = result_ctl==2'b0 ? alu_result:(result_ctl == 2'b01 ? mem_rdata : csr_rdata);
    assign reg_wdata = result;

    always@(*)begin
      if(upc_ctl == 0) upc = exu_upc;
      else upc = csr_upc;
    end

    always@(*)begin
      if(inst == 32'b00000000000100000000000001110011)begin
        exit = 1;
      end
      else begin
        exit = 0;
      end
    end
    endmodule
