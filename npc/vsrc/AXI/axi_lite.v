module AXI_LITE(
  input clk, rst,
  input reg io_slave_arvalid, io_slave_rready, io_slave_awvalid, io_slave_wvalid, io_slave_bready,
  input[31:0] io_slave_araddr, io_slave_awaddr, io_slave_wdata,
  input[7:0] io_slave_wstrb,
  output reg io_slave_arready, io_slave_rvalid, io_slave_awready, io_slave_wready, io_slave_bvalid,
  output reg[1:0] io_slave_rresp, io_slave_bresp,
  output[31:0] io_slave_rdata,

  input[31:0] rdata,
  output reg[31:0] wdata, raddr, waddr,
  output reg need_read, need_write
);
//reg[31:0] _raddr, _waddr, _wdata;

reg read_delay_start, read_delay_over;
wire[7:0] read_delay_count;
assign read_delay_count = 8'b101;

COUNT read_delay(.clk(clk), .rst(rst), .start(read_delay_start), .count(read_delay_count), .zero(read_delay_over));
//reg need_read;
//araddr
always@(posedge clk)begin
  if(rst) begin
    io_slave_arready <= 0;
    raddr <= 0;
    need_read <= 0;
  end
  else begin
    if(~arready && arvalid && ~need_read)begin
      io_slave_arready <= 1;
      raddr <= araddr;
      need_read <= 1;
      //read_delay_start <= 1;
    end
    else begin
      io_slave_arready <= 0;
    end
  end
end
//rdata
always@(posedge clk)begin
  if(rst)begin
    io_slave_rdata <= 0;
    io_slave_rvalid <= 0;
  end
  else begin
    if(need_read)begin
      //if(read_delay_over)begin
        io_slave_rvalid <= 1;
        io_slave_rresp <= 0;
        io_slave_rdata <= rdata;
        need_read <= 0;
        //read_delay_start <= 0;
      //end
    end
    else begin
      io_slave_rvalid <= 0;
    end
  end
end

//reg need_write;
//waddr
always@(posedge clk)begin
  if(rst)begin
    io_slave_awready <= 0;
    waddr <= 0;
  end
  else begin
    if(~io_slave_awready && io_slave_awvalid && io_slave_wvalid && ~need_write)begin
      io_slave_awready <= 1;
      waddr <= io_slave_awaddr;
      wdata <= io_slave_wdata;
      need_write <= 1;
    end
    else begin
      io_slave_awready <= 0;
    end
  end
end

//wdata
always@(posedge clk)begin
  if(rst)begin
    io_slave_wready <= 0;
  end
  else begin
    if(need_write)begin
      io_slave_wready <= 1;
      //pmem_write(_waddr, _wdata, io_slave_wstrb);
      need_write <= 0;
    end
    else begin
      io_slave_wready <= 0;
    end
  end
end

//bresp
always@(posedge clk)begin
  if(rst)begin
    io_slave_bvalid <= 0;
    io_slave_bresp <= 0;
  end
  else begin
    if(~io_slave_bvalid && io_slave_wvalid && io_slave_wready)begin
      io_slave_bvalid <= 1;
      io_slave_bresp <= 0;
    end
    else begin
      if(io_slave_bready && io_slave_bvalid)begin
        io_slave_bvalid <= 0;
      end
    end
  end
end

endmodule
