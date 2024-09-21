module ysyx_20020207_RAW (
    input idu_ready,
    input exu_ready,
    input lsu_ready,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] idu_rd,
    input idu_reg_wen,
    input [4:0] exu_rd,
    input exu_reg_wen,
    input [4:0] lsu_rd,
    input lsu_reg_wen,
    input [6:0] op,
    output is_raw
);

  wire is_lui = op == 7'b0110111;
  wire is_auipc = op == 7'b0010111;
  wire is_jal = op == 7'b1101111;
  wire is_jalr = op == 7'b1100111;
  wire is_l = op == 7'b0000011;
  wire is_i = op == 7'b0010011;
  wire is_r = op == 7'b0110011;
  wire is_b = op == 7'b1100011;
  wire is_s = op == 7'b0100011;

  wire idu_conflict = !(idu_ready && exu_ready && lsu_ready) && idu_reg_wen == 1 && (!is_jalr && !is_auipc && !is_lui && rs1 == idu_rd || (is_b || is_s || is_r) && rs2 == idu_rd);

  wire exu_conflict = !(exu_ready && lsu_ready) && exu_rd != 0 && exu_reg_wen == 1 && (!is_jalr && !is_auipc && !is_lui && rs1 == exu_rd || (is_b || is_s || is_r) && rs2 == exu_rd);

  wire lsu_conflict = !(lsu_ready) && lsu_rd != 0 && lsu_reg_wen == 1 && (!is_jalr && !is_auipc && !is_lui && rs1 == lsu_rd || (is_b || is_s || is_r) && rs2 == lsu_rd);

assign is_raw = exu_conflict || lsu_conflict;

endmodule
