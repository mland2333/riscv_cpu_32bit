`include "include.v"

module ysyx_20020207_XBAR(
  //与axi-arbiter连接接口
  input  arvalid, rready, awvalid, wvalid, bready, 
  input [31:0] araddr, awaddr,
  input [63:0] wdata,
  input [7:0] wstrb,
  output reg arready, rvalid, awready, wready, bvalid,
  output reg [1:0] rresp, bresp,
  output reg [63:0] rdata,
  
  //与ysyxsoc sram连接接口
  input arready1, rvalid1, awready1, wready1, bvalid1,
  input [1:0] rresp1, bresp1,
  input [63:0] rdata1,
  output reg arvalid1, rready1, awvalid1, wvalid1, bready1, 
  output reg [31:0] araddr1, awaddr1, 
  output reg [63:0] wdata1,
  output reg [7:0] wstrb1,
  
  //与clint接口
  input arready2, rvalid2, awready2, wready2, bvalid2,
  input [1:0] rresp2, bresp2,
  input [63:0] rdata2,
  output reg arvalid2, rready2, awvalid2, wvalid2, bready2, 
  output reg [31:0] araddr2, awaddr2, 
  output reg [63:0] wdata2,
  output reg [7:0] wstrb2,
  output reg high,
  /*input arready3, rvalid3, awready3, wready3, bvalid3,
  input [1:0] rresp3, bresp3,
  input [63:0] rdata3,
  output reg arvalid3, rready3, awvalid3, wvalid3, bready3, high, 
  output reg [31:0] araddr3, awaddr3,
  output reg [63:0] wdata3,
  output reg [7:0] wstrb3,*/

  output diff_skip
);
localparam OTHER_ZONE = 3'b000;
localparam PSRAM_ZONE = 3'b001;
localparam SRAM_ZONE = 3'b010;
localparam UART_ZONE = 3'b011;
localparam RTC_ZONE = 3'b100;
localparam FLASH_ZONE = 3'b101;

reg[2:0] read_zone;
reg[2:0] write_zone;
always@(*)begin
  read_zone = OTHER_ZONE;
  high = 0;
  if(araddr >= `UART && araddr < `UART + 32'h1000)
    read_zone = UART_ZONE;
  else if(araddr == `RTC_ADDR)
    read_zone = RTC_ZONE;
  else if(araddr == `RTC_ADDR_HIGH)begin
    read_zone = RTC_ZONE;
    high = 1;
  end
  else if(araddr >= `FLASH_BASE && araddr < `FLASH_BASE + `FLASH_SIZE)
    read_zone = FLASH_ZONE;
  else if(araddr >= `SRAM_BASE && araddr < `SRAM_BASE + `SRAM_SIZE)
    read_zone = SRAM_ZONE;
  else if(araddr >= `PSRAM_BASE && araddr < `PSRAM_BASE + `PSRAM_SIZE)
    read_zone = PSRAM_ZONE;
  else 
    read_zone = OTHER_ZONE;
end


always@(*)begin
  write_zone = OTHER_ZONE;
  if(awaddr >= `UART && awaddr < `UART + 32'h0fff)
    write_zone = UART_ZONE;
  else if(awaddr == `RTC_ADDR)
    write_zone = RTC_ZONE;
  else if(awaddr == `RTC_ADDR_HIGH)begin
    write_zone = RTC_ZONE;
  end
  else if(awaddr >= `FLASH_BASE && awaddr < `FLASH_BASE + `FLASH_SIZE)
    write_zone = FLASH_ZONE;
  else if(awaddr >= `SRAM_BASE && awaddr < `SRAM_BASE + `SRAM_SIZE)
    write_zone = SRAM_ZONE;
  else if(awaddr >= `PSRAM_BASE && awaddr < `PSRAM_BASE + `PSRAM_SIZE)
    write_zone = PSRAM_ZONE;
  else 
    write_zone = OTHER_ZONE;
end

assign diff_skip = read_zone == UART_ZONE || write_zone == UART_ZONE
                || read_zone == RTC_ZONE || write_zone == RTC_ZONE;

always@(*)begin
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
  if(read_zone == RTC_ZONE)begin
    arvalid2 = arvalid;
    rready2 = rready;
    araddr2 = araddr;
    arready = arready2;
    rvalid = rvalid2;
    rresp = rresp2;
    rdata = rdata2;
  end
  else begin
    arvalid1 = arvalid;
    rready1 = rready;
    araddr1 = araddr;
    arready = arready1;
    rvalid = rvalid1;
    rresp = rresp1;
    rdata = rdata1;
  end
end

always@(*)begin
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
  awready = 0;
  wready = 0;
  bvalid = 0;
  bresp = 0;
  if(write_zone == RTC_ZONE)begin
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
  else begin
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
end

endmodule
