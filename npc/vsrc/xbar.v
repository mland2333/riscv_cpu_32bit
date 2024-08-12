`include "include.v"

module XBAR(
  //与axi-arbiter连接接口
  input  arvalid, rready, awvalid, wvalid, bready, 
  input [31:0] araddr, awaddr, wdata,
  input [7:0] wstrb,
  output reg arready, rvalid, awready, wready, bvalid,
  output reg [1:0] rresp, bresp,
  output reg [31:0] rdata,
  
  //与sram连接接口
  input arready1, rvalid1, awready1, wready1, bvalid1,
  input [1:0] rresp1, bresp1,
  input [31:0] rdata1,
  output reg arvalid1, rready1, awvalid1, wvalid1, bready1, 
  output reg [31:0] araddr1, awaddr1, wdata1,
  output reg [7:0] wstrb1,
  
  //与uart接口
  input arready2, rvalid2, awready2, wready2, bvalid2,
  input [1:0] rresp2, bresp2,
  input [31:0] rdata2,
  output reg arvalid2, rready2, awvalid2, wvalid2, bready2, 
  output reg [31:0] araddr2, awaddr2, wdata2,
  output reg [7:0] wstrb2,

  input arready3, rvalid3, awready3, wready3, bvalid3,
  input [1:0] rresp3, bresp3,
  input [31:0] rdata3,
  output reg arvalid3, rready3, awvalid3, wvalid3, bready3, high, 
  output reg [31:0] araddr3, awaddr3, wdata3,
  output reg [7:0] wstrb3,

  output diff_skip
);

localparam SRAM_ZONE = 2'b00;
localparam UART_ZONE = 2'b01;
localparam RTC_ZONE = 2'b10;

reg[1:0] read_zone;
reg[1:0] write_zone;
always@(*)begin
  read_zone = SRAM_ZONE;
  high = 0;
  case(araddr)
    `UART:begin
      read_zone = UART_ZONE;
    end
    `RTC_ADDR:begin
      read_zone = RTC_ZONE;
    end
    `RTC_ADDR_HIGH:begin
      read_zone = RTC_ZONE;
      high = 1;
    end
    default:begin
      read_zone = SRAM_ZONE;
    end
  endcase
end

always@(*)begin
  write_zone = SRAM_ZONE;
  case(awaddr)
    `UART:begin
      write_zone = UART_ZONE;
    end
    `RTC_ADDR:begin
      write_zone = RTC_ZONE;
    end
    `RTC_ADDR_HIGH:begin
      write_zone = RTC_ZONE;
    end
    default:begin
      write_zone = SRAM_ZONE;
    end
  endcase
end

assign diff_skip = read_zone != SRAM_ZONE || write_zone != SRAM_ZONE;

always@(*)begin
  case(read_zone)
    SRAM_ZONE:begin
      arvalid1 = arvalid;
      rready1 = rready;
      araddr1 = araddr;
      arready = arready1;
      rvalid = rvalid1;
      rresp = rresp1;
      rdata = rdata1;
    end
    UART_ZONE:begin
      arvalid2 = arvalid;
      rready2 = rready;
      araddr2 = araddr;
      arready = arready2;
      rvalid = rvalid2;
      rresp = rresp2;
      rdata = rdata2;
    end
    RTC_ZONE:begin
      arvalid3 = arvalid;
      rready3 = rready;
      araddr3 = araddr;
      arready = arready3;
      rvalid = rvalid3;
      rresp = rresp3;
      rdata = rdata3;
    end
    default:begin
      arvalid1 = 0;
      rready1 = 0;
      araddr1 = 0;
      arvalid2 = 0;
      rready2 = 0;
      araddr2 = 0;
      arready = 0;
      rvalid = 0;
      rresp = 0;
      rdata = 0;
    end
  endcase
end

always@(*)begin
  case(write_zone)
    SRAM_ZONE:begin
      awvalid1 = awvalid;
      wvalid1 = wvalid;
      bready1 = bready;
      awaddr1 = awaddr;
      wdata1 = wdata;
      wstrb1 = wstrb;
      awready = awready1;
      wready = wready1;
      bvalid = bvalid1;
      bresp = bresp1;
    end
    UART_ZONE:begin
      awvalid2 = awvalid;
      wvalid2 = wvalid;
      bready2 = bready;
      awaddr2 = awaddr;
      wdata2 = wdata;
      wstrb2 = wstrb;
      awready = awready2;
      wready = wready2;
      bvalid = bvalid2;
      bresp = bresp2;
    end
    RTC_ZONE:begin
      awvalid3 = awvalid;
      wvalid3 = wvalid;
      bready3 = bready;
      awaddr3 = awaddr;
      wdata3 = wdata;
      wstrb3 = wstrb;
      awready = awready3;
      wready = wready3;
      bvalid = bvalid3;
      bresp = bresp3;
    end
    default:begin
      awvalid1 = 0;
      wvalid1 = 0;
      bready1 = 0;
      awaddr1 = 0;
      wdata1 = 0;
      wstrb1 = 0;
      awvalid2 = 0;
      wvalid2 = 0;
      bready2 = 0;
      awaddr2 = 0;
      wdata2 = 0;
      wstrb2 = 0;
      awvalid3 = 0;
      wvalid3 = 0;
      bready3 = 0;
      awaddr3 = 0;
      wdata3 = 0;
      wstrb3 = 0;
      awready = 0;
      wready = 0;
      bvalid = 0;
      bresp = 0;
    end
  endcase
end




endmodule
