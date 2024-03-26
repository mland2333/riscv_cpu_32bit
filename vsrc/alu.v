/*
module pg_generate(
    input[3:0] a, b,
    output[3:0] p, g
);
    assign p = a ^ b;
    assign g = a & b;
endmodule

module c_generate(
	input [3:0]p, g,
	input cin,
	output [3:0] cout
);
							
	assign cout[0]=g[0]|cin&p[0];
	assign cout[1]=g[1]|g[0]&p[1]|cin&p[1]&p[0];
	assign cout[2]=g[2]|g[1]&p[2]|g[0]&p[2]&p[1]|cin&p[2]&p[1]&p[0];
	assign cout[3]=g[3]|g[2]&p[3]|g[1]&p[3]&p[2]|g[0]&p[3]&p[2]&p[1]|cin&p[3]&p[2]&p[1]&p[0];

endmodule

module c_generate2bit(
	input [1:0]p, g,
	input cin,
	output [1:0] cout
);		
	assign cout[0]=g[0]|cin&p[0];
	assign cout[1]=g[1]|g[0]&p[1]|cin&p[1]&p[0];
endmodule


module pgm_generate(
    input[3:0] p, g,
    output pm, gm
);
    assign gm=g[3]|g[2]&p[3]|g[1]&p[3]&p[2]|g[0]&p[3]&p[2]&p[1];
	assign pm=p[3]&p[2]&p[1]&p[0];
endmodule


module pgmm_generate(
    input[3:0] pm, gm,
    output pmm, gmm
);
    assign gmm=gm[3]|gm[2]&pm[3]|gm[1]&pm[3]&pm[2]|gm[0]&pm[3]&pm[2]&pm[1];
	assign pmm=pm[3]&pm[2]&pm[1]&pm[0];
endmodule

module Adder_32bit(
    input [31:0]a, b,
    input cin,
    output [31:0]result,
    output cout, overflow, zero;
);
    wire [31:0] p, g, ci;
    wire [7:0] pm, gm, cm;
    wire [1:0] pmm, gmm;
    wire [2:0] cmm;
    assign cmm[0] = cin;
    generate
        genvar i;
        for(i = 0; i< 8; i++)begin
            //第一层的进位生成p与进位控制g
            pg_generate mypg(.a(a[i*4+3: i*4]), .b(b[i*4+3: i*4]), .p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]));
            //根据第二层cm生成的进位来生成第一层进位，第一层进位与p异或获得result
            c_generate myc(.p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]), .cin(cm[i]), .cout(ci[i*4+3: i*4]));
            //第二层的进位生成pm与进位控制gm
            pgm_generate mypgm(.p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]), .pm(pm[i]), .gm(gm[i]));
        end
        genvar j;
        for(j = 0; j < 2; j++)begin
            //第二层进位cm
            c_generate mycm(.p(pm[i*4+3: i*4]), .g(gm[i*4+3: i*4]), .cin(cmm[i]), .cout(cm[i*4+3: i*4]])); 
            //第三层的进位生成pmm与进位控制gmm
            pgmm_generate mypgmm(.pm(pm[j*4+3: j*4]), .gm([j*4+3: j*4]), .pmm(pmm[j]), .gmm(gmm[j]));
        end
    endgenerate
    c_generate2bit mycm2bit(.p(pmm[1:0]), .g(gmm[1:0]), .cin(cmm[0]), .cout(cmm[2:1]]));
    assign result = p ^ ci;
    assign cout = cmm[2];
    assign zero = ~(| result);
    assign overflow = a[31] == b[31] && a[31] != result[31];
endmodule
*/
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
    input[31:0] a,
    input[4:0] shift_num,
    input[1:0] shift_crl,
    output[31:0] shift_result
);
    localparam SLL = 2'b00;
    localparam SRA = 2'b01;
    localparam SRL = 2'b10;
    wire [31:0] sll_result, sra_result, srl_result;
    assign sll_result = a << shift_num;
    assign sra_result = a >>> shift_num;
    assign srl_result = a << shift_num;
    assign shift_result = (shift_crl == SLL)? sll_result :
                          (shift_crl == SRA)? sra_result :
                          (shift_crl == SRL)? srl_result : a;
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
    wire[31:0] adder_result, shift_result, logic_result, cmp_result;
    wire[31:0] l, r;
    reg[1:0] shift_crl, logic_crl, op_crl;
    //wire sub;
    assign l = a;
    //assign sub = func == SUB;
    assign r = sub? ~b : b;

    always@(*)begin
        case(alu_crl)
            4'b0000:
            begin
                op_crl = 2'b00;
            end
            default:
            begin
                op_crl = 2'b00;
            end
        endcase
    end
    Adder_32bit Adder(.a(l), .b(r), .cin(sub), .result(adder_result), .cout(CF), .zero(ZF), .overflow(OF));
    Shift_32bit Shift(.a(a), .shift_num(b[4:0]), .shift_crl(shift_crl), .shift_result(shift_result));
    Logic_32bit Logic(.a(a), .b(b), .logic_crl(logic_crl), .logic_result(logic_result));
    
    wire cmp;
    assign cmp = sign ? OF ^ adder_result[31] : CF;
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