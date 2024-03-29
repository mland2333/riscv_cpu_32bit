module top #(DATA_WIDTH = 32)(
    input clk,rst,valid,
    output [DATA_WIDTH-1 : 0] inst,
    output reg[DATA_WIDTH-1 : 0] pc, upc,
    output [31:0] result,
    output reg exit
);
    wire jump;
    wire [6:0]op;
    wire [2:0]func;
    wire [4:0]rs1, rs2, rd;
    wire [31:0] imm;
    wire ZF, OF, CF;
    wire[DATA_WIDTH-1 : 0] src1, src2; 
    //wire[DATA_WIDTH-1:0] result;
    reg wen;
    PC #(DATA_WIDTH) mpc(.clk(clk), .rst(rst), .upc(upc), .jump(jump), .pc(pc));
    IFU mifetch(.valid(valid), .pc(pc), .inst(inst));
    RegisterFile #(5, DATA_WIDTH) mreg(.clk(clk),.rdata1(src1),.raddr1(rs1),.rdata2(src2),.raddr2(rs2),.wdata(result),.waddr(rd),.wen(wen)); 
    IDU mdecode(.inst(inst), .op(op), .func(func), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm));
    EXU #(DATA_WIDTH) mexecute(.op(op), .func(func), .src1(src1), .src2(src2), .imm(imm), .pc(pc), .result(result), .upc(upc), .reg_wen(wen),.ZF(ZF),.OF(OF),.CF(CF),.jump(jump));

    always@(posedge clk)begin
      if((op==7'b1110011) && (func == 3'b0))begin
        exit <= 1;
      end
      else begin
        exit <= 0;
      end
    end
    endmodule
