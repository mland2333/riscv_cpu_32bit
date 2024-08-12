/*module Memory(
  input[31:0] raddr, waddr, wdata,
  input valid, wen, 
  input [7:0] wmask,
  output reg[31:0] rdata
);
always @(*) begin
  if (valid) begin // 有读写请求时
    rdata = pmem_read(raddr);
    if (wen) begin // 有写请求时
      pmem_write(waddr, wdata, wmask);
      //$display("write\n");
    end
  end
  else begin
    rdata = 0;
  end
end

endmodule*/


module LSU(
  input clk, rst, ifu_rdata_valid,
  input[31:0] raddr, waddr, wdata,
  input ren, wen,
  input[7:0] wmask,
  input[2:0] load_ctl,
  output reg[31:0] rdata,
  output lsu_finish
);
localparam IDLE = 2'b01;
localparam WAIT_READY = 2'b10;
reg read_wait_ready, write_wait_ready;
reg[31:0] _rdata;

reg arvalid, arready, rvalid, rready, rresp;
reg awvalid, wvalid, bready, awready, wready, bvalid;
reg[1:0] bresp;
reg[31:0] ifu_rdata;
SRAM ifu_sram(
  .clk(clk),
  .rst(rst),
  .arvalid(arvalid),
  .rready(rready),
  .awvalid(awvalid),
  .wvalid(wvalid),
  .bready(bready),
  .araddr(raddr),
  .awaddr(waddr),
  .wdata(wdata),
  .wstrb(wmask),
  .arready(arready),
  .rresp(rresp),
  .rvalid(rvalid),
  .awready(awready),
  .wready(wready),
  .bresp(bresp),
  .bvalid(bvalid),
  .rdata(_rdata)
);

//load
always@(posedge clk)begin
  if(rst)begin
    arvalid <= 0;
    read_wait_ready <= 0;
  end
  else begin
    if(!read_wait_ready && ren)begin
        if(ifu_rdata_valid)begin
          arvalid <= ren;
          read_wait_ready <= 1;
        end
    end
    else begin
        if(rvalid)begin
          arvalid <= 0;
          read_wait_ready <= 0;
        end
        else if(arvalid && arready)begin
          arvalid <= 0;
        end
    end
  end
end

//store
always@(posedge clk)begin
  if(rst)begin
    awvalid <= 0;
    write_wait_ready <= 0;
  end
  else begin
    if(!write_wait_ready && wen)begin
        if(ifu_rdata_valid)begin
          awvalid <= wen;
          wvalid <= wen;
          write_wait_ready <= 1;
        end
      end
    else begin
        if(wready)begin
          awvalid <= 0;
          write_wait_ready <= 0;
        end
        else if(awvalid && awready)begin
          awvalid <= 0;
        end
      end
  end
end

always@(posedge clk)begin
  lsu_finish <= (ifu_rdata_valid & ~wen &~ren) || wen&wready || ren&rvalid;
end


always@(*)begin
  case(load_ctl)
    3'b000: rdata = {{24{_rdata[7]}}, _rdata[7:0]};
    3'b001: rdata = {{16{_rdata[15]}}, _rdata[15:0]};
    3'b010: rdata = _rdata;
    3'b100: rdata = {24'b0, _rdata[7:0]};
    3'b101: rdata = {16'b0, _rdata[15:0]};
    default: rdata = _rdata;
  endcase
end
endmodule


