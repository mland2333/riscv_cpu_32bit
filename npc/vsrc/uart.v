`ifndef CONFIG_YSYXSOC
module UART(
  input clk, rst,
  input reg arvalid, rready, awvalid, wvalid, bready,
  input[31:0] araddr, awaddr, wdata,
  input[3:0] wstrb,
  output reg arready, rvalid, awready, wready, bvalid,
  output reg[1:0] rresp, bresp,
  output[31:0] rdata
);

reg need_write;
reg [31:0] _waddr, _wdata;
//waddr
always@(posedge clk)begin
  if(rst)begin
    awready <= 0;
    _waddr <= 0;
  end
  else begin
    if(~awready && awvalid && wvalid && ~need_write)begin
      awready <= 1;
      _waddr <= awaddr;
      _wdata <= wdata;
      need_write <= 1;
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
    if(need_write)begin
      wready <= 1;
      $write("%c", _wdata[7:0]);
      need_write <= 0;
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
    if(~bvalid && wvalid && wready)begin
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
`endif
