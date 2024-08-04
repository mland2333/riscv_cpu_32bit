`include "include.v"

module ysyx_20020207_EXU#(DATA_WIDTH = 32)(
    input [6:0] op,
    input [2:0] func,
    input [DATA_WIDTH-1:0]src1, src2, imm, pc, csr_rdata,
    output reg[DATA_WIDTH-1:0]upc, alu_a, alu_b,
    output reg reg_wen,
    output wire jump, mem_wen, mem_ren, csr_wen,
    output reg[2:0] csr_ctl,
    output reg[3:0] alu_ctl,
    output reg[1:0] result_ctl,
    output reg upc_ctl, sub, sign,
    output reg[3:0] wmask,
    output reg[2:0] load_ctl
);
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
    //reg [3:0] alu_ctl;
    //reg sub, sign;
    //reg[31:0] read_result, rdata;
    //reg[7:0] wmask;
    always@(*)begin
        sub = 0;
        sign = 0;
        reg_wen = 1;
        alu_a = src1;
        alu_b = src2;
        result_ctl = 0;
        csr_wen = 0;
        mem_wen = 0;
        mem_ren = 0;
        jump = 0;
        upc_ctl = 0;
        load_ctl = 0;
        case(op)
            7'b0010011:begin //I
                alu_b = imm;
                case(func)
                    3'b000:begin     //addi
                        alu_ctl = ADD;
                    end
                    3'b010:begin     //slti
                        alu_ctl = SET;
                        sub = 1;
                      end
                    3'b011:begin     //sltiu
                        alu_ctl = SET;
                        sub = 1;
                    end
                    3'b100:begin     //xori
                        alu_ctl = XOR;
                    end
                    3'b110:begin     //ori
                        alu_ctl = OR;
                    end
                    3'b111:begin     //andi
                        alu_ctl = AND;
                    end
                    3'b001:begin     //slli
                        alu_ctl = SLL;
                    end
                    3'b101:begin     //srai srli
                        if(imm[10] == 1) alu_ctl = SRA; //srai
                        else alu_ctl = SRL;             //srli
                    end
                    default:begin
                        alu_a = src1;
                        alu_b = src2;
                        {alu_ctl, sub, sign} = 0;
                    end
                endcase

            end
            7'b0000011:begin //lw, lh, lb, lhu, lbu
               alu_b = imm;
               mem_ren = 1;
               alu_ctl = ADD;
               result_ctl = 2'b01;
               load_ctl = func;
            end
            7'b0110011:begin  //R
               case(func)
                 3'b000:begin       // add sub
                   alu_ctl = ADD;
                   sub = imm[5];
                 end
                 3'b001:begin       // sll
                   alu_ctl = SLL;
                 end
                 3'b010:begin       // slt
                   alu_ctl = SET;
                   sign = 1;
                   sub = 1;
                 end
                 3'b011:begin       // sltu
                   alu_ctl = SET;
                   sub = 1;
                 end
                 3'b100:begin       //xor
                   alu_ctl = XOR;
                 end
                 3'b101:begin       //sra srl
                   if(imm[5] == 1) alu_ctl = SRA; //sra
                   else alu_ctl = SRL;             //srl
                 end
                 3'b110:begin       //or
                   alu_ctl = OR;
                 end
                 3'b111:begin       //and
                   alu_ctl = AND;
                 end
                 default:begin
                   alu_ctl = 0;
                 end
               endcase
             end
            7'b0010111:begin //auipc
                alu_a = pc;
                alu_b = imm;
                alu_ctl = ADD;
            end
            7'b1101111:begin //jal
                alu_a = pc;
                alu_b = 32'b100;
                jump = 1;
                alu_ctl = ADD;
                upc = pc + imm;
            end
            7'b1100111:begin //jalr
                alu_a = pc;
                alu_b = 32'b100;
                jump = 1;
                alu_ctl = ADD;
                upc = (src1 + imm)&~1;
            end
            7'b0110111:begin //lui
                alu_a = 32'b0;
                alu_b = imm;
                alu_ctl = ADD;
            end
            7'b0100011:begin //sw sh sb
                reg_wen = 0;
                alu_b = imm;
                alu_ctl = ADD;
                mem_wen = 1;
                case(func)
                  3'b000: wmask = 4'b0001;
                  3'b001: wmask = 4'b0011;
                  default: wmask = 4'b1111;
                endcase
            end
            7'b1100011:begin  //B
                reg_wen = 0;
                sub = 1;
                case(func)
                  3'b000: begin sign = 0; alu_ctl = BEQ; end  //beq
                  3'b001: begin sign = 0; alu_ctl = BNE; end  //bne
                  3'b100: begin sign = 1; alu_ctl = BLT; end //blt
                  3'b101: begin sign = 1; alu_ctl = BGE; end //bge
                  3'b110: begin sign = 0; alu_ctl = BLT; end //bltu
                  3'b111: begin sign = 0; alu_ctl = BGE; end //bgeu
                  default: begin sign = 0; alu_ctl = 0; end
                endcase
                upc = pc + imm;
                //$display("pc = 0x%x", pc);
                //$display("upc = 0x%x", upc);
            end
            7'b1110011:begin
              result_ctl = 2'b10;
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
                  alu_b = 0;
                  alu_ctl = ADD;
                  csr_wen = 1;
                  csr_ctl = `CSRW;
                end
                3'b010:begin
                  alu_b = csr_rdata;
                  alu_ctl = OR;
                  csr_wen = 1;
                  csr_ctl = `CSRW;
                end
                default:begin
                  alu_b = 0;
                  alu_ctl = 0;
                  csr_ctl = 0;
                end
              endcase

            end
            default:begin
                wmask = 0;
                alu_a = src1;
                alu_b = src2;
                {alu_ctl, sub, sign, reg_wen} = 0;
            end
        endcase
    end
    /*
    Alu_32bit myalu(.a(alu_a), .b(alu_b), .alu_ctl(alu_ctl), .sub(sub), .sign(sign), .result(alu_result), .ZF(ZF), .OF(OF), .CF(CF));
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
    */

    //assign exit = (op==7'b1110011) && (func == 3'b0);
endmodule
