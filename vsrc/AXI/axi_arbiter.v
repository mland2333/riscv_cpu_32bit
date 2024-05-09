module ysyx_20020207_ARBITER(
  input clk, rst,
  //读通道1
  input arvalid1, rready1,
  input [31:0] araddr1,
  output reg arready1, rvalid1,
  output reg[1:0] rresp1,
  output reg[63:0] rdata1,
  //写通道1
  input awvalid1, wvalid1, bready1,
  input [7:0] wstrb1,
  input [31:0] awaddr1, 
  input [63:0] wdata1,
  output reg awready1, wready1, bvalid1,
  output reg[1:0] bresp1,
  //读通道2
  input arvalid2, rready2,
  input [31:0] araddr2,
  output reg arready2, rvalid2,
  output reg[1:0] rresp2,
  output reg[63:0] rdata2,
  //写通道2
  input awvalid2, wvalid2, bready2,
  input [7:0] wstrb2,
  input [31:0] awaddr2,
  input [63:0] wdata2,
  output reg awready2, wready2, bvalid2,
  output reg[1:0] bresp2,
  //与sram连接通道
  input arready, rvalid, awready, wready, bvalid,
  input [1:0] rresp, bresp,
  input [63:0] rdata,
  output reg arvalid, rready, awvalid, wvalid, bready, 
  output reg[31:0] araddr, awaddr, 
  output reg[63:0] wdata,
  output reg[7:0] wstrb
);
localparam IDLE_READ = 2'b00;
localparam MEM1_READ = 2'b01;
localparam MEM2_READ = 2'b10;

localparam IDLE_WRITE = 2'b00;
localparam MEM1_WRITE = 2'b01;
localparam MEM2_WRITE = 2'b10;

reg[1:0] read_state, write_state;
reg[1:0] read_target, write_target;

always@(posedge clk)begin
  if(rst)begin
    read_state <= IDLE_READ;
  end
  else begin
    case(read_state)
      IDLE_READ:begin
        if(arvalid1)begin
          read_state <= MEM1_READ;
        end
        else if(arvalid2)begin
          read_state <= MEM2_READ;
        end
      end
      MEM1_READ:begin
        if(rvalid)begin
          read_state <= IDLE_READ;
        end
      end
      MEM2_READ:begin
        if(rvalid)begin
          read_state <= IDLE_READ;
        end
      end
      default:begin
        read_state <= IDLE_READ;
      end
    endcase
  end
end

always@(*)begin
  case(read_state)
    MEM1_READ:begin
      arvalid = arvalid1;
      rready = rready1;
      araddr = araddr1;
    end
    MEM2_READ:begin
      arvalid = arvalid2;
      rready = rready2;
      araddr = araddr2;
    end
    default:begin
      arvalid = 0;
      rready = 0;
      araddr = 0;
    end
  endcase
end

assign arready1 = read_state == MEM1_READ ? arready : 0;
assign rvalid1 = read_state == MEM1_READ ? rvalid : 0;
assign rresp1 = read_state == MEM1_READ ? rresp : 0;
assign rdata1 = read_state == MEM1_READ ? rdata : 0;

assign arready2 = read_state == MEM2_READ ? arready : 0;
assign rvalid2 = read_state == MEM2_READ ? rvalid : 0;
assign rresp2 = read_state == MEM2_READ ? rresp : 0;
assign rdata2 = read_state == MEM2_READ ? rdata : 0;




always@(posedge clk)begin
  if(rst)begin
    write_state <= IDLE_READ;
  end
  else begin
    case(write_state)
      IDLE_WRITE:begin
        if(awvalid1 && wvalid1)begin
          write_state <= MEM1_WRITE;
        end
        else if(awvalid2 && wvalid2)begin
          write_state <= MEM2_WRITE;
        end
      end
      MEM1_WRITE:begin
        if(bvalid && bready)begin
          write_state <= IDLE_WRITE;
        end
      end
      MEM2_WRITE:begin
        if(bvalid && bready)begin
          write_state <= IDLE_WRITE;
        end
      end
      default:begin
        write_state <= IDLE_WRITE;
      end
    endcase
  end
end

always@(*)begin
  case(write_state)
    MEM1_WRITE:begin
      awvalid = awvalid1;
      wvalid = wvalid1;
      bready = bready1;
      awaddr = awaddr1;
      wdata = wdata1;
      wstrb = wstrb1;
    end
    MEM2_WRITE:begin
      awvalid = awvalid2;
      wvalid = wvalid2;
      bready = bready2;
      awaddr = awaddr2;
      wdata = wdata2;
      wstrb = wstrb2;
    end
    default:begin
      awvalid = 0;
      wvalid = 0;
      bready = 0;
      awaddr = 0;
      wdata = 0;
      wstrb = 0;
    end
  endcase
end

assign awready1 = write_state == MEM1_WRITE ? awready : 0;
assign wready1 = write_state == MEM1_WRITE ? wready : 0;
assign bvalid1 = write_state == MEM1_WRITE ? bvalid : 0;
assign bresp1 = write_state == MEM1_WRITE ? bresp : 0;

assign awready2 = write_state == MEM2_WRITE ? awready : 0;
assign wready2 = write_state == MEM2_WRITE ? wready : 0;
assign bvalid2 = write_state == MEM2_WRITE ? bvalid : 0;
assign bresp2 = write_state == MEM2_WRITE ? bresp : 0;


endmodule
