module top #(DATA_WIDTH = 32)(
    input clk,rst,valid,
    output [DATA_WIDTH-1 : 0] inst,
    output reg[DATA_WIDTH-1 : 0] pc, upc,
    output [31:0] result,
    output reg exit, mem_wen
);
    wire jump;
    wire [6:0]op;
    wire [2:0]func;
    wire [4:0]rs1, rs2, rd;
    wire [31:0] imm;
    wire [31:0] csr_rdata, csr_wdata;
    wire ZF, OF, CF;
    wire[DATA_WIDTH-1 : 0] src1, src2;
    wire upc_ctl;
    //wire[DATA_WIDTH-1:0] result;
    reg wen, csr_wen;
    wire [2:0] csr_ctl;
    reg[31:0] alu_upc, csr_upc;
    PC #(DATA_WIDTH) mpc(.clk(clk), .rst(rst), .upc(upc), .jump(jump), .pc(pc));
    IFU mifetch(.valid(valid), .pc(pc), .inst(inst));
    RegisterFile #(5, DATA_WIDTH) mreg(.clk(clk),.rdata1(src1),.raddr1(rs1),.rdata2(src2),.raddr2(rs2),.wdata(result),.waddr(rd),.wen(wen)); 
    IDU mdecode(.inst(inst), .op(op), .func(func), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm));
    EXU #(DATA_WIDTH) mexecute(.op(op), .func(func), .src1(src1), .src2(src2), .imm(imm), .pc(pc), .csr_rdata(csr_rdata), .result(result), .csr_wdata(csr_wdata), .upc(alu_upc), .reg_wen(wen),.ZF(ZF),.OF(OF),.CF(CF),.jump(jump),.mem_wen(mem_wen), .csr_wen(csr_wen), .csr_ctl(csr_ctl), .upc_ctl(upc_ctl));
    CSRU mcsr(.clk(clk), .wen(csr_wen), .csr_ctl(csr_ctl), .addr(imm), .wdata(csr_wdata), .pc(pc), .rdata(csr_rdata), .upc(csr_upc));
    always@(*)begin
      if(upc_ctl == 0) upc = alu_upc;
      else upc = csr_upc;
    end
    always@(posedge clk)begin
      if(inst == 32'b00000000000100000000000001110011)begin
        exit <= 1;
      end
      else begin
        exit <= 0;
      end
    end
    endmodule
