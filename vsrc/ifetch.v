module IFU(
  input clk, rst, lsu_finish,
  input [31:0] pc,

  input ifu_rvalid, ifu_arready,
  input[1:0] ifu_rresp,
  input[31:0] ifu_rdata,
  output reg ifu_arvalid, ifu_rready,
  output[31:0] ifu_araddr,
  output reg[31:0] inst,
  output reg pc_wen, inst_valid
);
reg wait_ready;

assign ifu_araddr = pc;

always@(posedge clk)begin
  if(rst)begin
    inst <= 0;
    inst_valid <= 0;
  end
  else if(ifu_rvalid)begin
    inst <= ifu_rdata;
    inst_valid <= 1;
  end
  else begin
    inst_valid <= 0;
  end
end

always@(posedge clk)begin
  if(rst)begin
    ifu_arvalid <= 0;
    wait_ready <= 0;
    pc_wen <= 0;
  end
  else begin
    if(!wait_ready)begin
        ifu_arvalid <= 1;
        wait_ready <= 1;
        pc_wen <= 0;
    end
    else begin
        if(ifu_arready && ifu_arvalid)begin
          ifu_arvalid <= 0;
        end
        else if(lsu_finish)begin
          ifu_arvalid <= 0;
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


