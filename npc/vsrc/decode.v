module ysyx_20020207_IDU(
    input[31:0] inst,
    output[6:0] op,
    output[2:0] func,
    output[4:0] rs1, rs2, rd,
    output[31:0] imm
);
    reg[31:0] i;
    assign op = inst[6:0];
    assign func = inst[14:12];
    assign rd = inst[11:7];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    always@(*)begin
        case(inst[6:0])
            7'b0110111: //lui
            begin
                i = {inst[31:12], 12'b0};
            end
            7'b0010111: // auipc U
            begin
                i = {inst[31:12], 12'b0};
            end
            7'b0000011,
            7'b0010011,
            7'b1100111,
            7'b1110011: //I
            begin
                i = {{20{inst[31]}}, inst[31:20]};
            end
            7'b1101111: //J
            begin
                i = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            7'b0100011: //S
            begin
                i = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            7'b1100011: //B
            begin
                i = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            7'b0110011: //R
            begin
                i = {25'b0, inst[31:25]};
              end
            default:
            begin
                i = 32'b0;
            end
        endcase
    end

    assign imm = i;

endmodule
