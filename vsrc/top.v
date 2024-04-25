module top #(DATA_WIDTH = 32)(
    input clk,rst,read_valid,
    output [DATA_WIDTH-1 : 0] inst,
    output reg[DATA_WIDTH-1 : 0] pc, upc,
    output [31:0] result,
    output reg exit, mem_wen, jump, ifu_valid
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

    wire lsu_ready;
    IFU mifu(
      .clk(clk),
      .rst(rst),
      .pc_valid(read_valid),
      .lsu_ready(lsu_ready),
      .pc(pc),
      .inst(inst),
      .pc_wen(pc_wen),
      .ifu_valid(ifu_valid)
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
    wire lsu_valid, reg_wen;
    RegisterFile #(5, DATA_WIDTH) mreg(
      .clk(clk),
      .lsu_valid(lsu_valid),
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
    assign mem_raddr = alu_result;
    assign mem_waddr = alu_result;
    assign mem_wdata = src2;
    LSU mlsu(
      .clk(clk),
      .rst(rst),
      .ifu_valid(ifu_valid),
      .raddr(mem_raddr),
      .waddr(mem_waddr),
      .wdata(mem_wdata),
      .ren(mem_ren),
      .wen(mem_wen),
      .wmask(wmask),
      .rdata(mem_rdata),
      .lsu_ready(lsu_ready),
      .lsu_valid(lsu_valid),
      .load_ctl(load_ctl)
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
      .lsu_ready(lsu_ready),
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
