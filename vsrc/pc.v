module PC#(DATA_WIDTH) (
    input clk, rst,
    input [DATA_WIDTH-1 : 0] upc,
    input jump,
    output reg[DATA_WIDTH-1 : 0] pc
);
    always@(posedge clk)begin
        if(rst) pc <= 32'h80000000;
        else if(jump) pc <= upc;
        else pc <= pc + 4;
    end
endmodule

