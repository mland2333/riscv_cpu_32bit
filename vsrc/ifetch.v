module ysyx_20020207_IFU(
  input clk, rst, lsu_finish,
  input [31:0] pc,

  input  io_master_arready,
  output reg io_master_arvalid,
  output [31:0] io_master_araddr,
  
  output reg io_master_rready,
  input  io_master_rvalid,
  input  [1:0] io_master_rresp,
  input  [63:0] io_master_rdata,

  output reg[31:0] inst,
  output reg pc_wen, inst_valid
);
reg wait_ready;

assign io_master_araddr = pc;

always@(posedge clk)begin
  if(rst)begin
    inst <= 0;
    inst_valid <= 0;
  end
  else if(io_master_rvalid)begin
    inst <= io_master_rdata[31:0];
    inst_valid <= 1;
  end
  else begin
    inst_valid <= 0;
  end
end

always@(posedge clk)begin
  if(rst)begin
    io_master_arvalid <= 0;
    wait_ready <= 0;
    pc_wen <= 0;
  end
  else begin
    if(!wait_ready)begin
        io_master_arvalid <= 1;
        wait_ready <= 1;
        pc_wen <= 0;
    end
    else begin
        if(io_master_arready && io_master_arvalid)begin
          io_master_arvalid <= 0;
        end
        else if(lsu_finish)begin
          io_master_arvalid <= 0;
          wait_ready <= 0;
          pc_wen <= 1;
        end
        else begin
          pc_wen <= 0;
        end
      end
  end
end


endmodule


