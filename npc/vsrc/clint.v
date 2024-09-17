module ysyx_20020207_CLINT(
  input clock, reset, high,
  input reg arvalid, rready,
  input[31:0] araddr,
  output reg arready, rvalid,
  output reg[1:0] rresp,
  output[31:0] rdata
);

reg [63:0] mtime;

always@(posedge clock) begin
  if(reset)begin
    mtime <= 0;
  end
  else begin
    mtime <= mtime + 1;
  end
end

reg[31:0] _raddr;

reg need_read;
//araddr
always@(posedge clock)begin
  if(reset) begin
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
always@(posedge clock)begin
  if(reset)begin
    rdata <= 0;
    rvalid <= 0;
  end
  else begin
    if(need_read)begin
      //if(read_delay_over)begin
        rvalid <= 1;
        rresp <= 0;
        if(high)
          rdata <= mtime[63:32];
        else
          rdata <= mtime[31:0];
        need_read <= 0;
        //read_delay_start <= 0;
      //end
    end
    else begin
      rvalid <= 0;
    end
  end
end



endmodule
