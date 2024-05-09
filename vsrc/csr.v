`include "include.v"
module ysyx_20020207_CSRU(
  input clk, wen,
  input[2:0] csr_ctl,
  input [11:0]csr_addr,
  input[31:0] wdata, pc,
  input lsu_ready,
  output reg[31:0] rdata, upc
);
  localparam MSTATUS = 2'b00;
  localparam MTVEC = 2'b01;
  localparam MEPC = 2'b10;
  localparam MCAUSE = 2'b11;
  reg[31:0] csr [3:0];
  reg[1:0] addr_map;
  always@(*)begin
    case(csr_addr)
      12'h300: begin addr_map = MSTATUS; end
      12'h305: begin addr_map = MTVEC; end
      12'h341: begin addr_map = MEPC; end
      12'h342: begin addr_map = MCAUSE; end
      default: begin addr_map = 2'b00; end
    endcase
  end

   always @(posedge clk) begin
     if (lsu_ready && wen) begin
      case(csr_ctl)
        `CSRW:  begin csr[addr_map] <= wdata; end
        `ECALL: begin csr[MEPC] <= pc; csr[MCAUSE] <= 32'h0b; end
        default: begin end
      endcase
    end
  end

  always@(*)begin
    case(csr_ctl)
      `MRET:  begin upc = csr[MEPC]; end
      `ECALL: begin upc = csr[MTVEC]; end
      default begin upc = 0; end
    endcase
    if(addr_map == MSTATUS) rdata = 32'h1800;
    else rdata = csr[addr_map];
  end
  endmodule
