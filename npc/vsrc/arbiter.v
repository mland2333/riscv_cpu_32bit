module arbiter(
  input reg ifu_arvalid, ifu_rready, ifu_awvalid, ifu_wvalid, ifu_bready, 
  input[31:0] ifu_araddr, ifu_awaddr, ifu_wdata,
  input[7:0] ifu_wstrb,

  input reg lsu_arvalid, ifu_rready, ifu_awvalid, ifu_wvalid, ifu_bready, 
  input[31:0] lsu_araddr, ifu_awaddr, ifu_wdata,
  input[7:0] lsu_wstrb,

  input[1:0] which,

  output reg arvalid, rready, awvalid, wvalid, bready, 
  output[31:0] araddr, awaddr, wdata,
  output[7:0] wstrb
);

always@(*)begin
  case(which)
    2'b01:begin
      arvalid = ifu_arvalid;
      rready = ifu_rready;
      awvalid = ifu_awvalid;
      wvalid = ifu_wvalid;
      bready = ifu_bready;
      araddr = ifu_araddr;
      awaddr = ifu_awaddr;
      wdata = ifu_wdata;
      wstrb = ifu_wstrb;
    end
    2'b10:begin
      arvalid = lsu_arvalid;
      rready = lsu_rready;
      awvalid = lsu_awvalid;
      wvalid = lsu_wvalid;
      bready = lsu_bready;
      araddr = lsu_araddr;
      awaddr = lsu_awaddr;
      wdata = lsu_wdata;
      wstrb = lsu_wstrb;
    end
    default:begin
      rready = 0;
      awvalid = 0;
      wvalid = 0;
      bready = 0;
      araddr = 0;
      awaddr = 0;
      wdata = 0;
      wstrb = 0;
    end
  endcase
end




endmodule
