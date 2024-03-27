module EXU#(DATA_WIDTH = 32)(
    input [6:0] op,
    input [2:0] func,
    input [DATA_WIDTH-1:0]src1, src2, imm, pc,
    output [DATA_WIDTH-1:0]result,
    output reg[DATA_WIDTH-1:0]upc,
    output reg wen,
    output wire ZF, OF, CF, jump
);

    reg [3:0] alu_op;
    reg sub, sign;
    reg[31:0] a, b;
    always@(*)begin
        case(op)
            7'b0010011:begin //I
                wen = 1;
                a = src1;
                b = imm;
                case(func)
                    3'b000:begin     //addi
                        alu_op = 4'b0000;
                        sub = 0;
                        sign = 0;
                    end
                    default:begin
                        a = src1;
                        b = src2;
                        {alu_op, sub, sign} = 0;
                    end
                endcase
            end
            7'b0010111:begin //auipc
                wen = 1;
                a = pc;
                b = imm;
                alu_op = 4'b0000;
                sub = 0;
                sign = 0; 
            end
            7'b1101111:begin //jal
                wen = 1;
                a = pc;
                b = 32'b100;
                alu_op = 4'b0000;
                sub = 0;
                sign = 0;
                upc = pc + imm;
            end
            7'b1100111:begin //jalr
                wen = 1;
                a = pc;
                b = 32'b100;
                alu_op = 4'b0000;
                sub = 0;
                sign = 0;
                upc = (src1 + imm)&~1;
            end
            7'b0110111:begin //lui
                wen = 1;
                a = 32'b0;
                b = imm;
                alu_op = 4'b0000;
                sub = 0;
                sign = 0; 
            end
            default:begin
                a = src1;
                b = src2;
                {alu_op, sub, sign, wen} = 0;
            end
        endcase
    end
    Alu_32bit myalu(.a(a), .b(b), .alu_crl(alu_op), .sub(sub), .sign(sign), .result(result), .ZF(ZF), .OF(OF), .CF(CF));
    assign jump = (op==7'b1101111)||(op==7'b1100111);
    //assign exit = (op==7'b1110011) && (func == 3'b0);
endmodule
