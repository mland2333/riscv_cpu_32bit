module ysyx_20020207_PC #(
    DATA_WIDTH
) (
    input clock,
    input reset,
    output reg out_valid,
`ifdef CONFIG_PIPELINE
    input out_ready,
`else
    input wen,
`endif
    input [DATA_WIDTH-1 : 0] upc,
    input jump,
    output reg [DATA_WIDTH-1 : 0] pc
);
  reg after_rst;
  always @(posedge clock) begin
    if (reset) after_rst <= 1;
    else after_rst <= 0;
  end
`ifdef CONFIG_PIPELINE
  always @(posedge clock) begin
    if (reset | out_valid && out_ready | jump) out_valid <= 0;
    else if (!out_valid | after_rst) out_valid <= 1;
  end
  always @(posedge clock) begin
    if (reset) begin
      //`ifdef CONFIG_YSYXSOC
      pc <= 32'h30000000;
      //`else
      //pc <= 32'h80000000;
      //`endif
    end
    else if(jump)begin
      pc <= upc;
    end
    else if (out_valid && out_ready) begin
      pc <= pc + 4;
    end
  end
`else
  always @(posedge clock) begin
    if (wen | after_rst) out_valid <= 1;
    else out_valid <= 0;
  end

  always @(posedge clock) begin
    if (reset) begin
      //`ifdef CONFIG_YSYXSOC
      pc <= 32'h30000000;
      //`else
      //pc <= 32'h80000000;
      //`endif
    end else if (wen) begin
      if (jump) pc <= upc;
      else pc <= pc + 4;
    end
  end
`endif
endmodule

