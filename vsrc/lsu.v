module LSU(
  input clk, rst, inst_rvalid,
  input[31:0] raddr, waddr, wdata,
  input ren, wen,
  input[7:0] wmask,
  input[2:0] load_ctl,
  output reg[31:0] rdata,
  output lsu_finish,
  
  input reg lsu_rvalid, lsu_arready, lsu_awready, lsu_wready, lsu_bvalid, 
  input[1:0] rresp, bresp,
  input [31:0] lsu_rdata,
  output reg lsu_arvalid, lsu_rready, lsu_awvalid, lsu_wvalid, lsu_bready, 
  output[31:0] lsu_araddr, lsu_awaddr, lsu_wdata ,
  output[7:0] lsu_wstrb
);

assign lsu_wstrb = wmask;
assign lsu_araddr = raddr;
assign lsu_awaddr = waddr;
assign lsu_wdata = wdata;


reg[31:0] _rdata;
always@(posedge clk)begin
  if(lsu_rvalid)begin
    _rdata <= lsu_rdata;
  end
end

reg read_wait_ready, write_wait_ready;
//load
always@(posedge clk)begin
  if(rst)begin
    lsu_arvalid <= 0;
    read_wait_ready <= 0;
  end
  else begin
    if(!read_wait_ready && ren)begin
        if(inst_rvalid)begin
          lsu_arvalid <= ren;
          read_wait_ready <= 1;
        end
    end
    else begin
        if(lsu_arvalid && lsu_arready)begin
          lsu_arvalid <= 0;
          read_wait_ready <= 0;
        end
    end
  end
end

//store
always@(posedge clk)begin
  if(rst)begin
    lsu_awvalid <= 0;
    write_wait_ready <= 0;
    lsu_bready <= 0;
  end
  else begin
    if(!write_wait_ready && wen)begin
        lsu_bready <= 0;
        if(inst_rvalid)begin
          lsu_awvalid <= wen;
          lsu_wvalid <= wen;
          write_wait_ready <= 1;
        end
      end
    else begin
        if(lsu_wready)begin
          lsu_awvalid <= 0;
          lsu_wvalid <= 0;
          lsu_bready <= 1;
          write_wait_ready <= 0;
        end
        else if(lsu_awvalid && lsu_awready)begin
          lsu_awvalid <= 0;
        end
        else begin
          lsu_bready <= 0;
        end
      end
  end
end

always@(posedge clk)begin
  lsu_finish <= (~lsu_finish) && ((inst_rvalid & ~wen &~ren) || wen&lsu_wready || ren&lsu_rvalid);
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


