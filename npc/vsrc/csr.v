module ysyx_20020207_CSRU (
    input clock,
    input in_valid,
    input wen,
    input [2:0] ctrl,
    input [11:0] raddr,
    input [11:0] waddr,
    input [31:0] wdata,
    input [31:0] pc,
    output reg [31:0] rdata,
    output reg [31:0] upc
);
  `define MRET 3'b001
  `define ECALL 3'b010
  `define EBREAK 3'b011
  `define CSRW 3'b100
  localparam MSTATUS = 2'b00;
  localparam MTVEC = 2'b01;
  localparam MEPC = 2'b10;
  localparam MCAUSE = 2'b11;
  reg [31:0] csr[3:0];
  reg [11:0] addr;


  reg [1:0] raddr_map;
  always @(*) begin
    case (raddr)
      12'h300: begin
        raddr_map = MSTATUS;
      end
      12'h305: begin
        raddr_map = MTVEC;
      end
      12'h341: begin
        raddr_map = MEPC;
      end
      12'h342: begin
        raddr_map = MCAUSE;
      end
      default: begin
        raddr_map = 2'b00;
      end
    endcase
  end

  reg [1:0] waddr_map;
  always @(*) begin
    case (waddr)
      12'h300: begin
        waddr_map = MSTATUS;
      end
      12'h305: begin
        waddr_map = MTVEC;
      end
      12'h341: begin
        waddr_map = MEPC;
      end
      12'h342: begin
        waddr_map = MCAUSE;
      end
      default: begin
        waddr_map = 2'b00;
      end
    endcase
  end

  always @(posedge clock) begin
    if (in_valid && wen) begin
      if(ctrl == `CSRW) csr[waddr_map] <= wdata;
      else if(ctrl == `ECALL) begin
        csr[MEPC]   <= pc;
        csr[MCAUSE] <= 32'h0b;
      end
    end
  end
  assign csr[MSTATUS] = 32'h1800;
  assign rdata = csr[raddr_map];
  assign upc = ctrl == `MRET ? csr[MEPC] : ctrl == `ECALL ? csr[MTVEC] : 0;
endmodule
