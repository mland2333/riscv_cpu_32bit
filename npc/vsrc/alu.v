
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
    input  [31:0] a,
    input  [31:0] b,
    input  [ 1:0] logic_ctrl,
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
    input is_arch,
    input [31:0] a,
    input [31:0] b,
    input [3:0] ctrl,
    input sub,
    input sign,
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
  reg [1:0] shift_ctrl, logic_ctrl, op_ctrl;
   assign branch = is_beq && ZF || is_bne && ~ZF || is_blt && cmp || is_bge && ~cmp;
  assign op_ctrl = is_xor || is_or || is_and ? LOGIC : 
                     is_sll || is_srl || is_sra ? SHIFT :
                     is_beq || is_bne || is_blt || is_bge || is_slti || is_sltiu ? CMP : ADDER;
  assign logic_ctrl = ctrl[1:0];
  assign shift_ctrl = is_srl ? 2'b10 : is_sra ? 2'b01 : 2'b00;

  wire [31:0] adder_result;
  assign results[ADDER] = adder_result;
  Adder_32bit Adder (
      .a(a),
      .b(b),
      .cin(sub),
      .result(adder_result),
      .cout(CF)
  );
  Shift_32bit Shift (
      .a(a),
      .shift_num(b[4:0]),
      .shift_ctrl(shift_ctrl),
      .shift_result(results[SHIFT])
  );
  Logic_32bit Logic (
      .a(a),
      .b(b),
      .logic_ctrl(logic_ctrl),
      .logic_result(results[LOGIC])
  );
  assign ZF = ~(|adder_result);
  assign OF = a[31] == b[31] && a[31] != adder_result[31];
  wire high = adder_result[31];
  wire cmp = sign ? OF ^ high : ~CF;
  /*wire cmp, high;
    assign cmp = sign ? OF ^ high : ~CF;*/
  assign results[CMP] = {31'b0, cmp};
  assign result = results[op_ctrl];

endmodule
