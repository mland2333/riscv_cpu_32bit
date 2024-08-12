module ysyx_20020207_PC#(DATA_WIDTH) (
    input clk, rst, wen,
    input [DATA_WIDTH-1 : 0] upc,
    input jump,
    output reg[DATA_WIDTH-1 : 0] pc
);
    //reg pc_wen;
    always@(posedge clk)begin
        //pc_wen <= wen;
        if(rst) begin
          `ifdef CONFIG_YSYXSOC
          pc <= 32'h30000000;
          `else
          pc <= 32'h80000000;
          `endif
        end
        else if(wen) begin
          if(jump) pc <= upc;
          else pc <= pc + 4;
          //$display("pc = %h\n", pc);
        end
    end
endmodule

