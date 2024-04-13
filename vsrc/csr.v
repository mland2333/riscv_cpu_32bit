`include "include.v"
module CSRU(
  input clk, wen,
  input[2:0] csr_ctl,
  input[31:0] addr, wdata, pc,
  output reg[31:0] rdata, upc
);
  localparam MSTATUS = 2'b00;
  localparam MTEVC = 2'b01;
  localparam MEPC = 2'b10;
  localparam MCAUSE = 2'b11;
  reg[31:0] csr [2:0];
  reg[1:0] addr_map;
  always@(*)begin
    case(addr)
      32'h300: begin addr_map = MSTATUS; end
      32'h305: begin addr_map = MTEVC; end
      32'h341: begin addr_map = MEPC; end
      32'h342: begin addr_map = MCAUSE; end
      default: begin addr_map = 2'b00; end
    endcase
  end

   always @(posedge clk) begin
     if (wen) begin
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
      `ECALL: begin upc = csr[MTEVC]; end
      default begin upc = 0; end
    endcase
    rdata = csr[addr_map];
  end
  endmodule
