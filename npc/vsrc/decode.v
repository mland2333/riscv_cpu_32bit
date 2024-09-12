module ysyx_20020207_IDU(
    input clock,
    input reset,
    input inst_valid,
    input[31:0] inst_in,
  `ifdef CONFIG_PIPELINE
    input in_valid, out_ready,
    output out_valid, in_ready,
    input[31:0] pc_in,
    output[31:0] pc_out,
  `endif
    output[6:0] op,
    output[2:0] func,
    output[4:0] rs1, rs2, rd,
    output[31:0] imm,
    output decode_valid
);

reg[31:0] inst;
`ifdef CONFIG_PIPELINE
reg[31:0] pc;
always@(posedge clock)begin
  if(reset) in_ready <= 1;
  else if(in_valid && in_ready) in_ready <= 0;
  else if(!in_ready && out_valid && out_ready) in_ready <= 1;
end

always@(posedge clock)begin
  if(reset) out_valid <= 0;
  else if(!in_ready && inst_valid) out_valid <= 1;
  else if(out_valid && out_ready) out_valid <= 0;
end

always@(posedge clock)begin
  if(reset) inst <= 0;
  else if(in_valid && in_ready) inst <= inst_in;
end

always@(posedge clock)begin
  if(reset) pc <= 0;
  else pc <= pc_in;
end
assign pc_out = pc;
`else
always@(posedge clock)begin
  if(reset) inst <= 0;
  else if(inst_valid) inst <= inst_in;
end
`endif


reg _decode_valid;
assign decode_valid = _decode_valid;
always@(posedge clock)begin
  if(reset) _decode_valid <= 0;
  else if(inst_valid && ~_decode_valid) _decode_valid <= 1;
  else _decode_valid <= 0;
end


    assign op = inst[6:0];
    assign func = inst[14:12];
    assign rd = inst[11:7];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];

    wire [31:0]luii = {inst[31:12], 12'b0};
    wire [31:0]auipci = {inst[31:12], 12'b0};
    wire [31:0]ii = {{20{inst[31]}}, inst[31:20]};
    wire [31:0]ji = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0]si = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    wire [31:0]bi = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0]ri = {25'b0, _inst[31:25]};

    wire is_i = inst[6:0] == 7'b0000011 || inst[6:0] == 7'b0010011
            ||  inst[6:0] == 7'b1100111 || inst[6:0] == 7'b1110011;
    wire is_j = inst[6:0] == 7'b1101111;
    wire is_s = inst[6:0] == 7'b0100011;
    wire is_b = inst[6:0] == 7'b1100011;
    wire is_r = inst[6:0] == 7'b0110011;
    wire is_lui = inst[6:0] == 7'b0110111;
    wire is_auipc = inst[6:0] == 7'b0010111;

    wire[31:0] iri = is_i ? ii : ri;
    wire[31:0] jbi = is_j ? ji : bi;
    wire[31:0] sauipci = is_s ? si : auipci;
    wire[31:0] lui0i = is_lui ? luii : 0;

    wire is_iri = is_i | is_r;
    wire is_sauipci = is_s | is_auipc;

    wire[31:0] irjbi = is_iri ? iri : jbi;
    wire[31:0] sauipcluii = is_sauipci ? sauipci : lui0i;

    wire is_up = is_i | is_r | is_j | is_b;
    assign imm = is_up ? irjbi : sauipcluii;

    /*
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
*/
endmodule
