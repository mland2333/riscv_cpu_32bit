/*import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module SRAM(
  input clk, rst,
  input reg arvalid, rready, awvalid, wvalid, bready,
  input[31:0] araddr, awaddr, wdata,
  input[7:0] wstrb,
  output reg arready, rvalid, awready, wready, bvalid,
  output reg[1:0] rresp, bresp,
  output[31:0] rdata
);
reg[31:0] _raddr, _waddr, _wdata;
reg aw_en;

reg read_delay_start, read_delay_over;
wire[7:0] read_delay_count;
assign read_delay_count = 8'b101;

COUNT read_delay(.clk(clk), .rst(rst), .start(read_delay_start), .count(read_delay_count), .zero(read_delay_over));
reg need_read;
//araddr
always@(posedge clk)begin
  if(rst) begin
    arready <= 0;
    _raddr <= 0;
    need_read <= 0;
  end
  else begin
    if(~arready && arvalid && ~need_read)begin
      arready <= 1;
      _raddr <= araddr;
      need_read <= 1;
      //read_delay_start <= 1;
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
    if(need_read)begin
      //if(read_delay_over)begin
        rvalid <= 1;
        rresp <= 0;
        rdata <= pmem_read(_raddr);
        need_read <= 0;
        //read_delay_start <= 0;
      //end
    end
    else begin
      rvalid <= 0;
    end
  end
end

reg need_write;
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
      pmem_write(_waddr, _wdata, wstrb);
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

endmodule*/
