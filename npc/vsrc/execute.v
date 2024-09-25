module ysyx_20020207_EXU#(DATA_WIDTH = 32)(
    input clock,
    input reset,
    input [6:0] op_in,
    input [2:0] func_in,
    input [31:0] a_in,
    input [31:0] b_in,
    input [DATA_WIDTH-1:0]imm_in, src1_in,
    input sub_in,
    input in_valid,
    output reg out_valid,
  `ifdef CONFIG_PIPELINE
    input out_ready,
    output reg in_ready,
    input jump,
  `endif
    input [31:0] pc_in,
    output [31:0] pc_out,
    input [4:0] rd_in,
    output [4:0] rd_out,
    output [11:0] imm_out,
    output [DATA_WIDTH-1:0]upc,
    output reg_wen,
    output exu_jump, mem_wen, mem_ren, csr_wen,
    output [2:0] csr_ctrl,
    output upc_ctrl,
    output [3:0] wmask,
    output [2:0] load_ctrl,
    output fencei,
    output need_lsu,
    output [31:0] result,
    output [31:0] mem_wdata_in,
    output [31:0] mem_wdata_out
);
reg[6:0] op;
reg[2:0] func;
reg[31:0] imm, pc, src1, mem_wdata, csr_rdata;
reg[4:0] rd;
reg [31:0] a, b;
reg sub;
`ifdef CONFIG_PIPELINE
always@(posedge clock)begin
  if(reset || jump && out_ready || out_ready && !(in_valid && out_valid)) in_ready <= 1;
  else if(in_valid && in_ready) in_ready <= 0;
end

always@(posedge clock)begin
  if(reset || jump && out_ready) out_valid <= 0;
  else if(in_valid && (out_ready || in_ready)) out_valid <= 1;
  else if(out_valid && (in_ready || out_ready)) out_valid <= 0;
end
wire valid = in_valid && (in_ready || out_ready) && !jump;
always@(posedge clock)begin
  if(valid) op <= op_in;
end
always@(posedge clock)begin
  if(valid) func <= func_in;
end
always@(posedge clock)begin
  if(valid) imm <= imm_in;
end
always@(posedge clock)begin
  if(valid) pc <= pc_in;
end
always@(posedge clock)begin
  if(valid) src1 <= src1_in;
end
always@(posedge clock)begin
  if(valid) rd <= rd_in;
end
always@(posedge clock)begin
  if(valid) a <= a_in;
end
always@(posedge clock)begin
  if(valid) b <= b_in;
end
always@(posedge clock)begin
  if(valid) mem_wdata <= mem_wdata_in;
end
always@(posedge clock)begin
  if(valid) sub <= sub_in;
end
`else

always@(posedge clock)begin
  if(reset)begin
    {op, func, sub, imm, pc, src1, csr_rdata, mem_wdata} <= 0;
  end
  else begin
    if(in_valid)begin
      op <= op_in;
      func <= func_in;
      imm <= imm_in;
      pc <= pc_in;
      src1 <= src1_in;
      mem_wdata <= mem_wdata_in;
      out_valid <= 1;
      rd <= rd_in;
      sub <= sub_in;
    end
    else if(out_valid)
      out_valid <= 0;
  end
end

`endif

`define MRET 3'b001
`define ECALL 3'b010
`define EBREAK 3'b011
`define CSRW 3'b100
    localparam ADD = 4'b0000;
    localparam SLL = 4'b0001;
    localparam SLTI = 4'b0010;
    localparam SLTIU = 4'b0011;
    localparam XOR = 4'b0100;
    localparam SRI  = 4'b0101;
    localparam OR  = 4'b0110;
    localparam AND = 4'b0111;

    localparam BEQ = 4'b1000;
    localparam BNE = 4'b1001;
    localparam BLT = 4'b1100;
    localparam BGE = 4'b1101;
    localparam BLTU = 4'b1110;
    localparam BGEU = 4'b1111;
    //reg [3:0] alu_ctrl;
    //reg sub, sign;
    //reg[31:0] read_result, rdata;
    //reg[7:0] wmask;
    wire I = op == 7'b0010011;
    wire R = op == 7'b0110011;
    wire L = op == 7'b0000011;
    wire S = op == 7'b0100011;
    wire JAL = op == 7'b1101111;
    wire JALR = op == 7'b1100111;
    wire AUIPC = op == 7'b0010111;
    wire LUI = op == 7'b0110111;
    wire B = op == 7'b1100011;
    wire CSR = op == 7'b1110011;
    wire FENCEI = op == 7'b0001111;
    wire f000 = func == 3'b000;
    wire f001 = func == 3'b001;
    wire f010 = func == 3'b010;
    wire f011 = func == 3'b011;
    wire f100 = func == 3'b100;
    wire f101 = func == 3'b101;
    wire f110 = func == 3'b110;
    wire f111 = func == 3'b111;
    
    wire branch;
    wire sign = R && f010 || B && (f100 || f101) ? 1 : 0;
    assign reg_wen = !(S || B || FENCEI);
    assign csr_wen = CSR;
    assign mem_wen = S;
    assign mem_ren = L;
    assign exu_jump = JAL || JALR || CSR && f000 || branch;
    assign upc_ctrl = CSR && f000;
    assign load_ctrl = L ? func : 0;
    assign fencei = FENCEI;
    assign csr_ctrl = CSR ? (f000 ? (imm[1] ? `MRET : !imm[0] ? `ECALL : `EBREAK) :
      f001 || f010 ? `CSRW : 0) : 0;
    wire [3:0] alu_ctrl = I||R ? {1'b0, func} : B ? {1'b1, func} : CSR && f010 ? OR : ADD;
    assign wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
    wire is_arch = R && imm[5] == 1 || I && imm[10] == 1;
    wire [31:0] pc0 = (JAL | B ? pc : src1) + imm;
    assign upc = JAL || B ? pc0 : JALR ? pc0&~1 : 0;
    assign need_lsu = L | S;
    assign pc_out = pc;
    assign imm_out = imm[11:0];
    assign rd_out = rd;
    assign mem_wdata_out = mem_wdata;
    wire ZF, OF, CF;
    ysyx_20020207_ALU malu(
      .is_arch(is_arch),
      .a(a),
      .b(b),
      .ctrl(alu_ctrl),
      .sub(sub),
      .sign(sign),
      .result(result),
      .ZF(ZF),
      .OF(OF),
      .CF(CF),
      .branch(branch)
    );

endmodule

module ysyx_20020207_IDU_EXU(
  input[31:0] src1, src2, imm, csr_rdata, pc,
  input [6:0] op,
  input [2:0] func,
  output [31:0] a, b,
  output sub
);
    wire I = op == 7'b0010011;
    wire R = op == 7'b0110011;
    wire L = op == 7'b0000011;
    wire S = op == 7'b0100011;
    wire JAL = op == 7'b1101111;
    wire JALR = op == 7'b1100111;
    wire AUIPC = op == 7'b0010111;
    wire LUI = op == 7'b0110111;
    wire B = op == 7'b1100011;
    wire CSR = op == 7'b1110011;
    wire FENCEI = op == 7'b0001111;
    wire f000 = func == 3'b000;
    wire f001 = func == 3'b001;
    wire f010 = func == 3'b010;
    wire f011 = func == 3'b011;
    wire f100 = func == 3'b100;
    wire f101 = func == 3'b101;
    wire f110 = func == 3'b110;
    wire f111 = func == 3'b111;
    assign a = JAL || JALR || AUIPC ? pc : LUI ? 0 : src1;
    wire [31:0]b0 = I || L || AUIPC || S  || LUI ? imm : JAL || JALR ? 32'b100 :
            CSR && f001 ? 32'b0 : CSR && f010 ? csr_rdata : src2;
    assign sub = (I || R) && (f011 || f010) || B ? 1 : R && f000 ? imm[5] : 0;
    assign b = sub ? ~b0 : b0;

endmodule
