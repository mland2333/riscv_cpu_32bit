
module IFU_SRAM(
  input clk, valid,
  input [31:0] addr,
  output reg[31:0] data
);

always@(posedge clk)begin
  if(valid) data <= pmem_read(addr);
end

endmodule
 
module IFU(
  input clk, rst, pc_valid, lsu_ready,
  input [31:0] pc,
  output reg[31:0] inst,
  output reg pc_wen, ifu_valid
);
reg ifu_raddr_valid, ifu_rready;

reg[31:0] ifu_rdata;
SRAM ifu_sram(
  .clk(clk),
  .rst(rst),
  .arvalid(ifu_raddr_valid),
  .rready(),
  .awvalid(0),
  .wvalid(0),
  .bready(0),
  .araddr(pc),
  .awaddr(32'b0),
  .wdata(32'b0),
  .wstrb(8'b0),
  .arready(),
  .rresp(),
  .rvalid(),
  .awready(),
  .wready(),
  .bresp(),
  .bvalid(),
  .rdata(inst)
);

always@(posedge clk)begin
  if(rst)begin
    ifu_rready <= 0;
  end
  else begin
    if(~ifu_rready && ifu_rvalid)begin
      ifu_rready <= 1;
    end
    else if(ifu_ready)begin
      ifu_rready <= 0;
    end
  end
end

always@(posedge clk)begin
  if(rst)begin
    ifu_raddr_valid <= 0;
  end
  else begin
    if(!ifu_raddr_valid)begin
      ifu_raddr_valid <= 1;
    end
    else if(rvalid)begin
    end
  end
end





localparam IDLE = 2'b01;
localparam WAIT_READY = 2'b10;

reg[1:0] state;
/*
always@(posedge clk)begin
  pc_wen <= pc_valid;
end
*/
//reg valid;
always@(posedge clk)begin
  if(rst)begin
    state <= IDLE;
    pc_wen <= 0;
    ifu_valid <= 0;
  end
  else begin
    case(state)
      IDLE:begin
        state <= WAIT_READY;
        pc_wen <= 0;
        ifu_valid <= 1;
      end
      WAIT_READY:begin
        if(lsu_ready)begin
          state <= IDLE;
          pc_wen <= 1;
        end
        ifu_valid <= 0;
      end
      default:begin
        state <= 0;
        pc_wen <= 0;
        ifu_valid <= 0;
      end
    endcase
  end
end
IFU_SRAM ifu_sram(.clk(clk), .valid(ifu_valid), .addr(pc), .data(inst));

/*
always@(*)begin
  if(pc_valid)begin
    inst = pmem_read(pc);
    //$display("inst = %h\n", inst);
  end
  else begin
    inst = 32'b0;
  end
end*/
endmodule

/*MemFile imem(.raddr(pc[7:0]), .waddr(0), .wdata(0), .wen(0), .rdata(inst));*/
/*always@(posedge clk)begin
  if(rst) state <= IDLE;
  else begin*/

/*always@(posedge clk)begin
  if(rst) state <= IDLE;
  else begin
    case(state)
      IDLE:begin
        if(pc_valid)begin
          state <= WATI_READY;
        end
        else begin
          state <= IDLE;
        end
      end
      WATI_READY:begin
        if(idu_ready)begin
          state <= IDLE;
          ifu_valid <= 1;
        end
        else begin
          state <= WATI_READY;
          ifu_ready <= 0;
        end
      end
      default:state <= IDLE;
    endcase
  end
end
endmodule*/
