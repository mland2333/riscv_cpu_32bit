module top #(DATA_WIDTH = 32)(
    input clk,rst,read_valid,
    output [DATA_WIDTH-1 : 0] inst,
    output reg[DATA_WIDTH-1 : 0] pc, upc,
    output [31:0] result,
    output reg exit, mem_wen, jump, lsu_finish
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

    SRAM msram(
      .clk(clk),
      .rst(rst),
      .arvalid(arvalid),
      .rready(rready),
      .awvalid(awvalid),
      .wvalid(wvalid),
      .bready(bready),
      .araddr(araddr),
      .awaddr(awaddr),
      .wdata(wdata),
      .wstrb(wstrb),

      .arready(arready),
      .rresp(rresp), 
      .rvalid(rvalid), 
      .awready(awready), 
      .wready(wready), 
      .bvalid(bvalid),
      .bresp(bresp),
      .rdata(rdata)
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
