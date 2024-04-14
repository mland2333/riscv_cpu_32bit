`include "include.v"

module EXU#(DATA_WIDTH = 32)(
    input [6:0] op,
    input [2:0] func,
    input [DATA_WIDTH-1:0]src1, src2, imm, pc, csr_rdata,
    output reg [DATA_WIDTH-1:0]result, csr_wdata,
    output reg[DATA_WIDTH-1:0]upc,
    output reg reg_wen,
    output wire ZF, OF, CF, jump, mem_wen, csr_wen,
    output reg[2:0] csr_ctl,
    output upc_ctl
);
    localparam ADD = 4'b0000;
    localparam XOR = 4'b0001;
    localparam OR  = 4'b0010;
    localparam AND = 4'b0011;
    localparam SLL = 4'b0100;
    localparam SRL = 4'b0101;
    localparam SRA = 4'b0110;
    localparam SET = 4'b1000;
    reg [3:0] alu_op;
    reg sub, sign;
    reg[31:0] a, b, alu_result;
    reg[31:0] read_result, rdata;
    reg[7:0] wmask;
    reg valid;
    always@(*)begin
        sub = 0;
        sign = 0;
        reg_wen = 1;
        a = src1;
        b = src2;
        result = alu_result;
        csr_wdata = alu_result;
        csr_wen = 0;
        mem_wen = 0;
        valid = 0;
        jump = 0;
        upc_ctl = 0;
        case(op)
            7'b0010011:begin //I
                b = imm;
                case(func)
                    3'b000:begin     //addi
                        alu_op = ADD;
                    end
                    3'b010:begin     //slti
                        alu_op = SET;
                        sub = 1;
                      end
                    3'b011:begin     //sltiu
                        alu_op = SET;
                        sub = 1;
                    end
                    3'b100:begin     //xori
                        alu_op = XOR;
                    end
                    3'b110:begin     //ori
                        alu_op = OR;
                    end
                    3'b111:begin     //andi
                        alu_op = AND;
                    end
                    3'b001:begin     //slli
                        alu_op = SLL;
                    end
                    3'b101:begin     //srai srli
                        if(imm[10] == 1) alu_op = SRA; //srai
                        else alu_op = SRL;             //srli
                    end
                    default:begin
                        a = src1;
                        b = src2;
                        {alu_op, sub, sign} = 0;
                    end
                endcase

            end
            7'b0000011:begin //lw, lh, lb, lhu, lbu
               b = imm;
               valid = 1;
               alu_op = ADD;
               result = read_result;
            end
            7'b0110011:begin  //R
               case(func)
                 3'b000:begin       // add sub
                   alu_op = ADD;
                   sub = imm[5];
                 end
                 3'b001:begin       // sll
                   alu_op = SLL;
                 end
                 3'b010:begin       // slt
                   alu_op = SET;
                   sign = 1;
                   sub = 1;
                 end
                 3'b011:begin       // sltu
                   alu_op = SET;
                   sub = 1;
                 end
                 3'b100:begin       //xor
                   alu_op = XOR;
                 end
                 3'b101:begin       //sra srl
                   if(imm[5] == 1) alu_op = SRA; //sra
                   else alu_op = SRL;             //srl
                 end
                 3'b110:begin       //or
                   alu_op = OR;
                 end
                 3'b111:begin       //and
                   alu_op = AND;
                 end
                 default:begin
                   alu_op = 0;
                 end
               endcase
             end
            7'b0010111:begin //auipc
                a = pc;
                b = imm;
                alu_op = ADD;
            end
            7'b1101111:begin //jal
                a = pc;
                b = 32'b100;
                jump = 1;
                alu_op = ADD;
                upc = pc + imm;
            end
            7'b1100111:begin //jalr
                a = pc;
                b = 32'b100;
                jump = 1;
                alu_op = ADD;
                upc = (src1 + imm)&~1;
            end
            7'b0110111:begin //lui
                a = 32'b0;
                b = imm;
                alu_op = ADD;
            end
            7'b0100011:begin //sw sh sb
                reg_wen = 0;
                b = imm;
                alu_op = ADD;
                valid = 1;
                mem_wen = 1;
                case(func)
                  3'b000: wmask = 8'b00000001;
                  3'b001: wmask = 8'b00000011;
                  default: wmask = 8'b00001111;
                endcase
            end
            7'b1100011:begin  //B
                reg_wen = 0;
                alu_op = SET;
                sub = 1;
                case(func)
                  3'b000: begin sign = 0; jump = (ZF==1); end  //beq
                  3'b001: begin sign = 0; jump = (ZF==0); end  //bne
                  3'b100: begin sign = 1; jump = (result[0]==1); end //blt
                  3'b101: begin sign = 1; jump = (result[0]==0); end //bge
                  3'b110: begin sign = 0; jump = (result[0]==1); end //bltu
                  3'b111: begin sign = 0; jump = (result[0]==0); end //bgeu
                  default: begin sign = 0; jump = 0; end
                endcase
                upc = pc + imm;
                //$display("pc = 0x%x", pc);
                //$display("upc = 0x%x", upc);
            end
            7'b1110011:begin
              result = csr_rdata;
              case(func)
                3'b000:begin
                  if(imm[1]==1) csr_ctl = `MRET;
                  else if(imm[0]==0) csr_ctl = `ECALL;
                  else csr_ctl = `EBREAK;
                  csr_wen = 1;
                  jump = 1;
                  upc_ctl = 1;
                end
                3'b001:begin
                  b = 0;
                  alu_op = ADD;
                  csr_wen = 1;
                  csr_ctl = `CSRW;
                end
                3'b010:begin
                  b = csr_rdata;
                  alu_op = OR;
                  csr_wen = 1;
                  csr_ctl = `CSRW;
                end
                default:begin
                  b = 0;
                  alu_op = 0;
                  csr_ctl = 0;
                end
              endcase

            end
            default:begin
                wmask = 0;
                a = src1;
                b = src2;
                {alu_op, sub, sign, reg_wen} = 0;
            end
        endcase
    end
    Alu_32bit myalu(.a(a), .b(b), .alu_crl(alu_op), .sub(sub), .sign(sign), .result(alu_result), .ZF(ZF), .OF(OF), .CF(CF));
    Memory mem(.raddr(alu_result), .waddr(alu_result), .wdata(src2), .valid(valid), .wen(mem_wen), .wmask(wmask), .rdata(rdata));

    always@(*)begin
      case(func)
        3'b000: read_result = {{24{rdata[7]}}, rdata[7:0]};
        3'b001: read_result = {{16{rdata[15]}}, rdata[15:0]};
        3'b010: read_result = rdata;
        3'b100: read_result = {24'b0, rdata[7:0]};
        3'b101: read_result = {16'b0, rdata[15:0]};
        default: read_result = rdata;
      endcase
    end

    //assign exit = (op==7'b1110011) && (func == 3'b0);
endmodule
