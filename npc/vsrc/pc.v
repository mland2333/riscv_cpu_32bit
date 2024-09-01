module ysyx_20020207_PC#(DATA_WIDTH) (
    input clk, rst, wen,
    input [DATA_WIDTH-1 : 0] upc,
    input jump,
    output reg[DATA_WIDTH-1 : 0] pc,
    output reg pc_ready
);
    //reg pc_wen;
    reg after_rst;
    always@(posedge clk)begin
        //pc_wen <= wen;
        if(rst) begin
          `ifdef CONFIG_YSYXSOC
          pc <= 32'h30000000;
          `else
          pc <= 32'h80000000;
          `endif
          pc_ready <= 0;
          after_rst <= 1;
        end
        else if(wen) begin
          if(jump) pc <= upc;
          else pc <= pc + 4;
          pc_ready <= 1;
          //$display("pc = %h\n", pc);
        end
        else if(after_rst)begin
          after_rst <= 0;
          pc_ready <= 1;
        end
        else begin
          pc_ready <= 0;
        end
    end
endmodule

