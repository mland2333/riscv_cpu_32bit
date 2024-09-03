module ysyx_20020207_EXU#(DATA_WIDTH = 32)(
    input clock,
    input reset,
    input decode_valid,
    input [6:0] op,
    input [2:0] func,
    input [DATA_WIDTH-1:0]src1, src2, imm, pc, csr_rdata,
    output reg[DATA_WIDTH-1:0]upc, alu_a, alu_b,
    output reg reg_wen,
    output wire jump, mem_wen, mem_ren, csr_wen,
    output reg[2:0] csr_ctrl,
    output reg[3:0] alu_ctrl,
    output reg[1:0] result_ctrl,
    output reg upc_ctrl, sub, sign,
    output reg[3:0] wmask,
    output reg[2:0] load_ctrl,
    output fencei,
    output reg ctrl_valid
);
reg[6:0] _op;
reg[2:0] _func;
reg[31:0] _imm, _pc, _src1, _src2, _csr_rdata;
always@(posedge clock)begin
  if(reset)begin
    {_op, _func, _imm, _pc, _src1, _src2, _csr_rdata} <= 0;
    ctrl_valid <= 0;
  end
  else begin
    if(decode_valid)begin
      _op <= op;
      _func <= func;
      _imm <= imm;
      _pc <= pc;
      _src1 <= src1;
      _src2 <= src2;
      _csr_rdata <= csr_rdata;
      ctrl_valid <= 1;
    end
    else if(ctrl_valid)
      ctrl_valid <= 0;
  end
end
`define MRET 3'b001
`define ECALL 3'b010
`define EBREAK 3'b011
`define CSRW 3'b100
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
    //reg [3:0] alu_ctrl;
    //reg sub, sign;
    //reg[31:0] read_result, rdata;
    //reg[7:0] wmask;
    always@(*)begin
        sub = 0;
        sign = 0;
        reg_wen = 1;
        alu_a = _src1;
        alu_b = _src2;
        result_ctrl = 0;
        csr_wen = 0;
        mem_wen = 0;
        mem_ren = 0;
        jump = 0;
        upc_ctrl = 0;
        load_ctrl = 0;
        fencei = 0;
        case(_op)
            7'b0010011:begin //I
                alu_b = _imm;
                case(_func)
                    3'b000:begin     //addi
                        alu_ctrl = ADD;
                    end
                    3'b010:begin     //slti
                        alu_ctrl = SET;
                        sub = 1;
                      end
                    3'b011:begin     //sltiu
                        alu_ctrl = SET;
                        sub = 1;
                    end
                    3'b100:begin     //xori
                        alu_ctrl = XOR;
                    end
                    3'b110:begin     //ori
                        alu_ctrl = OR;
                    end
                    3'b111:begin     //andi
                        alu_ctrl = AND;
                    end
                    3'b001:begin     //slli
                        alu_ctrl = SLL;
                    end
                    3'b101:begin     //srai srli
                        if(_imm[10] == 1) alu_ctrl = SRA; //srai
                        else alu_ctrl = SRL;             //srli
                    end
                    default:begin
                        alu_a = _src1;
                        alu_b = _src2;
                        {alu_ctrl, sub, sign} = 0;
                    end
                endcase

            end
            7'b0000011:begin //lw, lh, lb, lhu, lbu
               alu_b = _imm;
               mem_ren = 1;
               alu_ctrl = ADD;
               result_ctrl = 2'b01;
               load_ctrl = _func;
            end
            7'b0110011:begin  //R
               case(_func)
                 3'b000:begin       // add sub
                   alu_ctrl = ADD;
                   sub = _imm[5];
                 end
                 3'b001:begin       // sll
                   alu_ctrl = SLL;
                 end
                 3'b010:begin       // slt
                   alu_ctrl = SET;
                   sign = 1;
                   sub = 1;
                 end
                 3'b011:begin       // sltu
                   alu_ctrl = SET;
                   sub = 1;
                 end
                 3'b100:begin       //xor
                   alu_ctrl = XOR;
                 end
                 3'b101:begin       //sra srl
                   if(_imm[5] == 1) alu_ctrl = SRA; //sra
                   else alu_ctrl = SRL;             //srl
                 end
                 3'b110:begin       //or
                   alu_ctrl = OR;
                 end
                 3'b111:begin       //and
                   alu_ctrl = AND;
                 end
                 default:begin
                   alu_ctrl = 0;
                 end
               endcase
             end
            7'b0010111:begin //auipc
                alu_a = _pc;
                alu_b = _imm;
                alu_ctrl = ADD;
            end
            7'b1101111:begin //jal
                alu_a = _pc;
                alu_b = 32'b100;
                jump = 1;
                alu_ctrl = ADD;
                upc = pc + _imm;
            end
            7'b1100111:begin //jalr
                alu_a = _pc;
                alu_b = 32'b100;
                jump = 1;
                alu_ctrl = ADD;
                upc = (_src1 + _imm)&~1;
            end
            7'b0110111:begin //lui
                alu_a = 32'b0;
                alu_b = _imm;
                alu_ctrl = ADD;
            end
            7'b0100011:begin //sw sh sb
                reg_wen = 0;
                alu_b = _imm;
                alu_ctrl = ADD;
                mem_wen = 1;
                case(_func)
                  3'b000: wmask = 4'b0001;
                  3'b001: wmask = 4'b0011;
                  default: wmask = 4'b1111;
                endcase
            end
            7'b1100011:begin  //B
                reg_wen = 0;
                sub = 1;
                case(_func)
                  3'b000: begin sign = 0; alu_ctrl = BEQ; end  //beq
                  3'b001: begin sign = 0; alu_ctrl = BNE; end  //bne
                  3'b100: begin sign = 1; alu_ctrl = BLT; end //blt
                  3'b101: begin sign = 1; alu_ctrl = BGE; end //bge
                  3'b110: begin sign = 0; alu_ctrl = BLT; end //bltu
                  3'b111: begin sign = 0; alu_ctrl = BGE; end //bgeu
                  default: begin sign = 0; alu_ctrl = 0; end
                endcase
                upc = _pc + _imm;
                //$display("pc = 0x%x", pc);
                //$display("upc = 0x%x", upc);
            end
            7'b1110011:begin
              result_ctrl = 2'b10;
              case(_func)
                3'b000:begin
                  if(_imm[1]==1) csr_ctrl = `MRET;
                  else if(_imm[0]==0) csr_ctrl = `ECALL;
                  else csr_ctrl = `EBREAK;
                  csr_wen = 1;
                  jump = 1;
                  upc_ctrl = 1;
                end
                3'b001:begin
                  alu_b = 0;
                  alu_ctrl = ADD;
                  csr_wen = 1;
                  csr_ctrl = `CSRW;
                end
                3'b010:begin
                  alu_b = _csr_rdata;
                  alu_ctrl = OR;
                  csr_wen = 1;
                  csr_ctrl = `CSRW;
                end
                default:begin
                  alu_b = 0;
                  alu_ctrl = 0;
                  csr_ctrl = 0;
                end
              endcase
            end
            7'b0001111:begin
              if(func == 001)begin
                fencei = 1;
                reg_wen = 0;
              end
            end
            default:begin
                fencei = 0;
                wmask = 0;
                alu_a = _src1;
                alu_b = _src2;
                {alu_ctrl, sub, sign, reg_wen} = 0;
            end
        endcase
    end
    /*
    Alu_32bit myalu(.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .sub(sub), .sign(sign), .result(alu_result), .ZF(ZF), .OF(OF), .CF(CF));
    Memory mem(.raddr(alu_result), .waddr(alu_result), .wdata(_src2), .valid(valid), .wen(mem_wen), .wmask(wmask), .rdata(rdata));
    
    always@(*)begin
      case(_func)
        3'b000: read_result = {{24{rdata[7]}}, rdata[7:0]};
        3'b001: read_result = {{16{rdata[15]}}, rdata[15:0]};
        3'b010: read_result = rdata;
        3'b100: read_result = {24'b0, rdata[7:0]};
        3'b101: read_result = {16'b0, rdata[15:0]};
        default: read_result = rdata;
      endcase
    end
    */

    //assign exit = (op==7'b1110011) && (_func == 3'b0);
endmodule
