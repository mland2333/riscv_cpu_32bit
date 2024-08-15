module ysyx_20020207_IDU(
    input clock,
    input reset,
    input inst_valid,
    input[31:0] inst,
    output[6:0] op,
    output[2:0] func,
    output[4:0] rs1, rs2, rd,
    output[31:0] imm,
    output decode_valid
);
reg[31:0] _inst;
always@(posedge clock)begin
  if(reset) _inst <= 0;
  else if(inst_valid) _inst <= inst;
end

reg _decode_valid;
assign decode_valid = _decode_valid;
always@(posedge clock)begin
  if(reset) _decode_valid <= 0;
  else if(inst_valid && ~_decode_valid) _decode_valid <= 1;
  else _decode_valid <= 0;
end


    reg[31:0] i;
    assign op = _inst[6:0];
    assign func = _inst[14:12];
    assign rd = _inst[11:7];
    assign rs1 = _inst[19:15];
    assign rs2 = _inst[24:20];
    always@(*)begin
        case(_inst[6:0])
            7'b0110111: //lui
            begin
                i = {_inst[31:12], 12'b0};
            end
            7'b0010111: // auipc U
            begin
                i = {_inst[31:12], 12'b0};
            end
            7'b0000011,
            7'b0010011,
            7'b1100111,
            7'b1110011: //I
            begin
                i = {{20{_inst[31]}}, _inst[31:20]};
            end
            7'b1101111: //J
            begin
                i = {{11{_inst[31]}}, _inst[31], _inst[19:12], _inst[20], _inst[30:21], 1'b0};
            end
            7'b0100011: //S
            begin
                i = {{20{_inst[31]}}, _inst[31:25], _inst[11:7]};
            end
            7'b1100011: //B
            begin
                i = {{19{_inst[31]}}, _inst[31], _inst[7], _inst[30:25], _inst[11:8], 1'b0};
            end
            7'b0110011: //R
            begin
                i = {25'b0, _inst[31:25]};
              end
            default:
            begin
                i = 32'b0;
            end
        endcase
    end

    assign imm = i;

endmodule
