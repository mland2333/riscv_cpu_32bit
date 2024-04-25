
module Adder_32bit(
    input [31:0]a, b,
    input cin,
    output [31:0]result,
    output cout, overflow, zero
);
    assign {cout, result} = a + b + {31'b0, cin};
    assign zero = ~(| result); 
    assign overflow = a[31] == b[31] && a[31] != result[31];
endmodule

module Shift_32bit(
    input signed[31:0] a,
    input[4:0] shift_num,
    input[1:0] shift_ctl,
    output reg[31:0] shift_result
);
    localparam SLL = 2'b00;
    localparam SRA = 2'b01;
    localparam SRL = 2'b10;

    wire [31:0] sll_result, sra_result, srl_result;
    assign sll_result = a << shift_num;
    assign sra_result = a >>> shift_num;
    assign srl_result = a >> shift_num;
    always@(*)begin
      case(shift_ctl)
        SLL: shift_result = sll_result;
        SRA: shift_result = sra_result;
        SRL: shift_result = srl_result;
        default: shift_result = a;
      endcase
    end
endmodule

module Logic_32bit(
    input[31:0] a,b,
    input[1:0] logic_ctl,
    output [31:0] logic_result
);
    localparam AND = 2'b00;
    localparam OR  = 2'b01;
    localparam XOR = 2'b10;
    wire [31:0] and_result, or_result, xor_result;
    assign and_result = a & b;
    assign or_result = a | b;
    assign xor_result = a ^ b;
    assign logic_result = (logic_ctl == AND)? and_result :
                          (logic_ctl == OR )? or_result  :
                          (logic_ctl == XOR)? xor_result : a;

endmodule

module ALU(
    input [31:0] a, b,
    input [3:0] alu_ctl,
    input sub, sign,
    output reg [31:0] result,
    output reg ZF, OF, CF, branch
);
    localparam ADDER = 2'b00;
    localparam SHIFT = 2'b01;
    localparam LOGIC = 2'b10;
    localparam CMP   = 2'b11;

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
    wire[31:0] adder_result, shift_result, logic_result, cmp_result;
    wire[31:0] l, r;
    reg[1:0] shift_ctl, logic_ctl, op_ctl;
    //wire sub;
    assign l = a;
    //assign sub = func == SUB;
    assign r = sub? ~b : b;

    always@(*)begin
        branch = 0;
        op_ctl = 2'b00;
        logic_ctl = 0;
        shift_ctl = 0;
        case(alu_ctl)
            ADD:
            begin
                op_ctl = ADDER;
            end
            XOR:
            begin
              op_ctl = LOGIC;
              logic_ctl = 2'b10;
            end
            OR:
            begin
              op_ctl = LOGIC;
              logic_ctl = 2'b01;
            end
            AND:
            begin
              op_ctl = LOGIC;
              logic_ctl = 2'b00;
            end
            SLL:begin
              op_ctl = SHIFT;
            end
            SRL:begin
              op_ctl = SHIFT;
              shift_ctl = 2'b10;
            end
            SRA:begin
              op_ctl = SHIFT;
              shift_ctl = 2'b01;
            end
            BEQ:begin
              op_ctl = CMP;
              branch = ZF;
            end
            BNE:begin
              op_ctl = CMP;
              branch = ~ZF;
            end
            BLT:begin
              op_ctl = CMP;
              branch = cmp;
            end
            BGE:begin
              op_ctl = CMP;
              branch = ~cmp;
            end
            SET:begin
              op_ctl = CMP;
            end
            default:
            begin
                op_ctl = 2'b00;
            end
        endcase
    end
    Adder_32bit Adder(.a(l), .b(r), .cin(sub), .result(adder_result), .cout(CF), .zero(ZF), .overflow(OF));
    Shift_32bit Shift(.a(a), .shift_num(b[4:0]), .shift_ctl(shift_ctl), .shift_result(shift_result));
    Logic_32bit Logic(.a(a), .b(b), .logic_ctl(logic_ctl), .logic_result(logic_result));
    
    wire cmp;
    assign cmp = sign ? OF ^ adder_result[31] : ~CF;
    assign cmp_result = {31'b0, cmp};

    always@(*)begin
        case(op_ctl)
            ADDER: result = adder_result;
            SHIFT: result = shift_result;
            LOGIC: result = logic_result;
            CMP  : result = cmp_result;
        endcase
    end


endmodule
