module SRAM(
  input clk, rst, arvalid, rready, awvalid, wvalid, bready, 
  input[31:0] araddr, awaddr, wdata,
  input [7:0] wstrb,
  output arready, rresp, rvalid, awready, wready, bresp, bvalid,
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
    else begin
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
    if(~rvalid && arready && arvalid)begin
      rvalid <= 1;
      rresp <= 1;
      rdata <= pmem_read(raddr);
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
    aw_en <= 1;
    waddr <= 0;
  end
  else begin
    if(~awready && awvalid && wvalid && aw_en)begin
      awready <= 1;
      aw_en <= 0;
      waddr <= awaddr;
    end
    else if(bready && bvalid)begin
      awready <= 0;
      aw_en <= 1;
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
    if(~awready && awvalid && wvalid && aw_en)begin
      wready <= 1;
      pmem_write(waddr, wdata, wstrb);
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
