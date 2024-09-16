
module Adder_32bit (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] result,
    output cout
);
  assign {cout, result} = a + b + {31'b0, cin};
  //assign {cout, result} = 0;
  //assign zero = ~(| result); 
  //assign overflow = a[31] == b[31] && a[31] != result[31];
  //assign high = result[31];
endmodule

module Shift_32bit (
    input signed [31:0] a,
    input [4:0] shift_num,
    input [1:0] shift_ctrl,
    output reg [31:0] shift_result
);
  localparam SLL = 2'b00;
  localparam SRA = 2'b01;
  localparam SRL = 2'b10;

  wire [31:0] results[4];
  assign results[SLL] = a << shift_num;
  assign results[SRA] = a >>> shift_num;
  assign results[SRL] = a >> shift_num;
  assign results[3]   = a;
  assign shift_result = results[shift_ctrl];
endmodule

module Logic_32bit (
    input [31:0] a,
    input [31:0] b,
    input [1:0] logic_ctrl,
    output [31:0] logic_result
);
  localparam XOR = 2'b00;
  localparam OR = 2'b10;
  localparam AND = 2'b11;
  wire [31:0] results[4];
  assign results[AND] = a & b;
  assign results[OR]  = a | b;
  assign results[XOR] = a ^ b;
  assign results[1]   = a;
  assign logic_result = results[logic_ctrl];

endmodule

module ysyx_20020207_ALU (
    input clock,
    input is_arch_in,
    input [31:0] a_in,
    input [31:0] b_in,
    input [3:0] ctrl_in,
    input sub_in,
    input sign_in,
    input reg_wen_in,
    input reg_addr_in,
    output reg_wen_out,
    output reg_addr_out,
    input in_valid,
    output out_valid,
`ifdef CONFIG_PIPELINE
    input out_ready,
    output in_ready,
`endif
    output [31:0] result,
    output ZF,
    output OF,
    output CF,
    output branch
);
  localparam ADDER = 2'b00;
  localparam SHIFT = 2'b01;
  localparam LOGIC = 2'b10;
  localparam CMP = 2'b11;
  /*
    localparam ADD = 4'b0000;
    localparam XOR = 4'b0001;
    localparam OR  = 4'b0010;
    localparam AND = 4'b0011;
    localparam SLL = 4'b0100;
    localparam SRL = 4'b0101;
    localparam SRA = 4'b0110;

    localparam BEQ = 4'b1000;
    localparam BNE = 4'b1001;
    localparam BLT = 4'b1010;
    localparam BGE = 4'b1011;
    localparam SET = 4'b1100;
*/
  localparam ADD = 4'b0000;
  localparam SLL = 4'b0001;
  localparam SLTI = 4'b0010;
  localparam SLTIU = 4'b0011;
  localparam XOR = 4'b0100;
  localparam SRI = 4'b0101;
  localparam OR = 4'b0110;
  localparam AND = 4'b0111;

  localparam BEQ = 4'b1000;
  localparam BNE = 4'b1001;
  localparam BLT = 4'b1100;
  localparam BGE = 4'b1101;
  localparam BLTU = 4'b1110;
  localparam BGEU = 4'b1111;

  reg is_arch;
  wire is_add = ctrl == ADD;
  wire is_sll = ctrl == SLL;
  wire is_slti = ctrl == SLTI;
  wire is_sltiu = ctrl == SLTIU;
  wire is_xor = ctrl == XOR;
  wire is_sra = ctrl == SRI && is_arch;
  wire is_srl = ctrl == SRI && !is_arch;
  wire is_or = ctrl == OR;
  wire is_and = ctrl == AND;
  wire is_beq = ctrl == BEQ;
  wire is_bne = ctrl == BNE;
  wire is_blt = ctrl == BLT || ctrl == BLTU;
  wire is_bge = ctrl == BGE || ctrl == BGEU;



  wire [31:0] results[4];
  reg [31:0] l, r;
  reg sub, sign;
  reg [3:0] ctrl;
  reg [1:0] shift_ctrl, logic_ctrl, op_ctrl;
  reg reg_wen;
  reg [4:0] reg_addr;
`ifdef CONFIG_PIPELINE
  always @(posedge clock) begin
    if (reset) in_ready <= 1;
    else if (in_valid && in_ready) in_ready <= 0;
    else if (!in_ready && out_valid && out_ready) in_ready <= 1;
  end
  always @(posedge clock) begin
    if (reset) out_valid <= 0;
    else if (!in_ready && inst_valid) out_valid <= 1;
    else if (out_valid && out_ready) out_valid <= 0;
  end

  always@(posedge clock)begin
    if(in_valid && in_ready) r <= a_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) ctrl <= ctrl_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) sub <= sub_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) sign <= sign_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) l <= sub_in ? ~b_in : b_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) is_arch <= is_arch_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) reg_wen <= reg_wen_in;
  end
  always@(posedge clock)begin
    if(in_valid && in_ready) reg_addr <= reg_addr_in;
  end
 `else
  //wire sub;
  always@(posedge clock)begin
    if(in_valid) r <= a_in;
  end
  always@(posedge clock)begin
    if(in_valid) ctrl <= ctrl_in;
  end
  always@(posedge clock)begin
    if(in_valid) sub <= sub_in;
  end
  always@(posedge clock)begin
    if(in_valid) sign <= sign_in;
  end
  always@(posedge clock)begin
    if(in_valid) l <= sub_in ? ~b_in : b_in;
  end
  always@(posedge clock)begin
    if(in_valid) is_arch <= is_arch_in;
  end
  always@(posedge clock)begin
    if(in_valid) reg_wen <= reg_wen_in;
  end
  always@(posedge clock)begin
    if(in_valid) reg_addr <= reg_addr_in;
  end
  always@(posedge clock)begin
    if(in_valid) out_valid <= 1;
    else out_valid <= 0;
`endif
  assign branch = is_beq && ZF || is_bne && ~ZF || is_blt && cmp || is_bge && ~cmp;
  assign op_ctrl = is_xor || is_or || is_and ? LOGIC : 
                     is_sll || is_srl || is_sra ? SHIFT :
                     is_beq || is_bne || is_blt || is_bge || is_slti || is_sltiu ? CMP : ADDER;
  assign logic_ctrl = ctrl[1:0];
  assign shift_ctrl = is_srl ? 2'b10 : is_sra ? 2'b01 : 2'b00;
  assign reg_addr_out = reg_addr;
  assign reg_wen_out = reg_wen;
  Adder_32bit Adder (
      .a(l),
      .b(r),
      .cin(sub),
      .result(results[ADDER]),
      .cout(CF)
  );
  Shift_32bit Shift (
      .a(r),
      .shift_num(l[4:0]),
      .shift_ctrl(shift_ctrl),
      .shift_result(results[SHIFT])
  );
  Logic_32bit Logic (
      .a(r),
      .b(l),
      .logic_ctrl(logic_ctrl),
      .logic_result(results[LOGIC])
  );
  assign ZF = ~(|results[ADDER]);
  assign OF = l[31] == r[31] && l[31] != results[ADDER][31];
  wire high = results[ADDER][31];
  wire cmp = sign ? OF ^ high : ~CF;
  /*wire cmp, high;
    assign cmp = sign ? OF ^ high : ~CF;*/
  assign results[CMP] = {31'b0, cmp};
  assign result = results[op_ctrl];

endmodule
