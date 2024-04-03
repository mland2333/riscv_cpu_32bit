
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
    input[1:0] shift_crl,
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
      case(shift_crl)
        SLL: shift_result = sll_result;
        SRA: shift_result = sra_result;
        SRL: shift_result = srl_result;
        default: shift_result = a;
      endcase
    end
endmodule

module Logic_32bit(
    input[31:0] a,b,
    input[1:0] logic_crl,
    output [31:0] logic_result
);
    localparam AND = 2'b00;
    localparam OR  = 2'b01;
    localparam XOR = 2'b10;
    wire [31:0] and_result, or_result, xor_result;
    assign and_result = a & b;
    assign or_result = a | b;
    assign xor_result = a ^ b;
    assign logic_result = (logic_crl == AND)? and_result :
                          (logic_crl == OR )? or_result  :
                          (logic_crl == XOR)? xor_result : a;

endmodule

module Alu_32bit(
    input [31:0] a, b,
    input [3:0] alu_crl,
    input sub, sign,
    output reg [31:0] result,
    output reg ZF, OF, CF
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
    localparam SET = 4'b1000;
    wire[31:0] adder_result, shift_result, logic_result, cmp_result;
    wire[31:0] l, r;
    reg[1:0] shift_crl, logic_crl, op_crl;
    //wire sub;
    assign l = a;
    //assign sub = func == SUB;
    assign r = sub? ~b : b;

    always@(*)begin
        case(alu_crl)
            ADD:
            begin
                op_crl = ADDER;
                logic_crl = 0;
                shift_crl = 0;
            end
            XOR:
            begin
              op_crl = LOGIC;
              logic_crl = 2'b10;
              shift_crl = 0;
            end
            OR:
            begin
              op_crl = LOGIC;
              logic_crl = 2'b01;
              shift_crl = 0;
            end
            AND:
            begin
              op_crl = LOGIC;
              logic_crl = 2'b00;
              shift_crl = 0;
            end
            SLL:begin
              op_crl = SHIFT;
              logic_crl = 0;
              shift_crl = 2'b00;
            end
            SRL:begin
              op_crl = SHIFT;
              logic_crl = 0;
              shift_crl = 2'b10;
            end
            SRA:begin
              op_crl = SHIFT;
              logic_crl = 0;
              shift_crl = 2'b01;
            end
            SET:
            begin
              op_crl = CMP;
              logic_crl = 0;
              shift_crl = 0;
            end
            default:
            begin
                op_crl = 2'b00;
                logic_crl = 0;
                shift_crl = 0;
            end
        endcase
    end
    Adder_32bit Adder(.a(l), .b(r), .cin(sub), .result(adder_result), .cout(CF), .zero(ZF), .overflow(OF));
    Shift_32bit Shift(.a(a), .shift_num(b[4:0]), .shift_crl(shift_crl), .shift_result(shift_result));
    Logic_32bit Logic(.a(a), .b(b), .logic_crl(logic_crl), .logic_result(logic_result));
    
    wire cmp;
    assign cmp = sign ? OF ^ adder_result[31] : ~CF;
    assign cmp_result = {31'b0, cmp};

    always@(*)begin
        case(op_crl)
            ADDER: result = adder_result;
            SHIFT: result = shift_result;
            LOGIC: result = logic_result;
            CMP  : result = cmp_result;
        endcase
    end


endmodule
