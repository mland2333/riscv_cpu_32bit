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

reg read_delay_start, read_delay_over;
wire[7:0] read_delay_count;
assign read_delay_count = 8'b101;

COUNT read_delay(.clk(clk), .rst(rst), .start(read_delay_start), .count(read_delay_count), .zero(read_delay_over));
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
      read_delay_start <= 1;
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
      //if(read_delay_over)begin
        rvalid <= 1;
        rresp <= 0;
        rdata <= pmem_read(raddr);
        //read_delay_start <= 0;
      //end
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
      wready <= 1;
      pmem_write(awaddr, wdata, wstrb);
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
