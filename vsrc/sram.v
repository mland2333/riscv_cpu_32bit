import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module SRAM(
  input clk, rst,
  input reg arvalid, rready, awvalid, wvalid, bready, 
  input[31:0] araddr, awaddr, wdata,
  input[7:0] wstrb,
  output reg arready, rresp, rvalid, awready, wready, bvalid,
  output reg[1:0] bresp,
  output[31:0] rdata
);
reg[31:0] raddr, waddr;
reg aw_en;

//araddr
always@(posedge clk)begin
  if(rst) begin
    arready <= 0;
    raddr <= 0;
  end
  else begin
    if(~arready && arvalid)begin
      arready <= 1;
      raddr <= araddr;
    end
    else if(rvalid)begin
      arready <= 0;
    end
  end
end

//rdata
always@(posedge clk)begin
  if(rst)begin
    rdata <= 0;
    rvalid <= 0;
  end
  else begin
    if(arready && arvalid)begin
      #5 rvalid <=  1;
      #5 rresp <= 0;
      #5 rdata <= pmem_read(raddr);
    end
    else begin
      rvalid <= 0;
    end
  end
end

//waddr
always@(posedge clk)begin
  if(rst)begin
    awready <= 0;
    waddr <= 0;
  end
  else begin
    if(~awready && awvalid && wvalid)begin
      awready <= 1;
      waddr <= awaddr;
    end
    else begin
      awready <= 0;
    end
  end
end

//wdata
always@(posedge clk)begin
  if(rst)begin
    wready <= 0;
  end
  else begin
    if(~awready && awvalid && wvalid)begin
      wready <= #5 1;
      #5 pmem_write(awaddr, wdata, wstrb);
    end
    else begin
      wready <= 0;
    end
  end
end

//bresp
always@(posedge clk)begin
  if(rst)begin
    bvalid <= 0;
    bresp <= 0;
  end
  else begin
    if(~bvalid && awvalid && awready && wvalid && wready)begin
      bvalid <= 1;
      bresp <= 0;
    end
    else begin
      if(bready && bvalid)begin
        bvalid <= 0;
      end
    end
  end
end

endmodule
