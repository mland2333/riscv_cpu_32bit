module ysyx_20020207_XBAR(
  //与axi-arbiter连接接口
  input  arvalid, rready, awvalid, wvalid, bready, 
  input [31:0] araddr, awaddr,
  input [31:0] wdata,
  input [3:0] wstrb,
  output reg arready, rvalid, awready, wready, bvalid,
  output reg [1:0] rresp, bresp,
  output reg [31:0] rdata,
  
  //ysyxsoc or sram
  input arready1, rvalid1, awready1, wready1, bvalid1,
  input [1:0] rresp1, bresp1,
  input [31:0] rdata1,
  output reg arvalid1, rready1, awvalid1, wvalid1, bready1, 
  output reg [31:0] araddr1, awaddr1, 
  output reg [31:0] wdata1,
  output reg [3:0] wstrb1,
  
  //clint
  input arready2, rvalid2,
  input [1:0] rresp2,
  input [31:0] rdata2,
  output reg arvalid2, rready2, 
  output reg [31:0] araddr2, 
  output reg high,
/*`ifndef CONFIG_YSYXSOC
  //uart
  input arready3, rvalid3, awready3, wready3, bvalid3,
  input [1:0] rresp3, bresp3,
  input [31:0] rdata3,
  output reg arvalid3, rready3, awvalid3, wvalid3, bready3, 
  output reg [31:0] araddr3, awaddr3,
  output reg [31:0] wdata3,
  output reg [3:0] wstrb3,
`endif
*/
  output diff_skip
);

`define DEVICE_BASE 32'ha0000000

//`ifdef CONFIG_YSYXSOC
`define UART 32'h10000000
`define RTC_ADDR 32'h2000bff8
`define RTC_ADDR_HIGH 32'h2000bffc
/*`else 
`define UART 32'ha00003f8
`define RTC_ADDR 32'ha0000048
`define RTC_ADDR_HIGH 32'ha000004c
`endif
*/
`define FLASH_BASE 32'h30000000
`define FLASH_SIZE 32'h10000000

`define SRAM_BASE 32'h0f000000
`define SRAM_SIZE 32'h00002000

`define PSRAM_BASE 32'h80000000
`define PSRAM_SIZE 32'h20000000

`define SDRAM_BASE 32'ha0000000
`define SDRAM_SIZE 32'h20000000

`define GPIO_BASE 32'h10002000
`define GPIO_SIZE 32'h00000010

localparam OTHER_ZONE = 3'b000;
localparam PSRAM_ZONE = 3'b001;
localparam SRAM_ZONE = 3'b010;
localparam UART_ZONE = 3'b011;
localparam RTC_ZONE = 3'b100;
localparam FLASH_ZONE = 3'b101;
localparam SDRAM_ZONE = 3'b110;
localparam GPIO_ZONE = 3'b111;

reg[2:0] read_zone;
reg[2:0] write_zone;
reg read_diff_skip, write_diff_skip;
always@(*)begin
  read_zone = OTHER_ZONE;
  read_diff_skip = 0;
  high = 0;
  if(araddr >= `UART && araddr < `UART + 32'h1000)begin
    read_zone = UART_ZONE;
    read_diff_skip = 1;
  end
  else if(araddr == `RTC_ADDR)begin
    read_zone = RTC_ZONE;
    read_diff_skip = 1;
  end
  else if(araddr == `RTC_ADDR_HIGH)begin
    read_zone = RTC_ZONE;
    high = 1;
    read_diff_skip = 1;
  end
  else if(araddr >= `FLASH_BASE && araddr < `FLASH_BASE + `FLASH_SIZE)
    read_zone = FLASH_ZONE;
  else if(araddr >= `SRAM_BASE && araddr < `SRAM_BASE + `SRAM_SIZE)
    read_zone = SRAM_ZONE;
  else if(araddr >= `PSRAM_BASE && araddr < `PSRAM_BASE + `PSRAM_SIZE)
    read_zone = PSRAM_ZONE;
  else if(araddr >= `SDRAM_BASE && araddr < `SDRAM_BASE + `SDRAM_SIZE)
    read_zone = SDRAM_ZONE;
  else if(araddr >= `GPIO_BASE && araddr < `GPIO_BASE + `GPIO_SIZE)begin
    read_diff_skip = 1;
    read_zone = GPIO_ZONE;
  end
  else 
    read_zone = OTHER_ZONE;
end


always@(*)begin
  write_zone = OTHER_ZONE;
  write_diff_skip = 0;
  if(awaddr >= `UART && awaddr < `UART + 32'h0fff)begin
    write_diff_skip = 1;
    write_zone = UART_ZONE;
  end
  //else if(awaddr >= `FLASH_BASE && awaddr < `FLASH_BASE + `FLASH_SIZE)
  //  write_zone = FLASH_ZONE;
  else if(awaddr >= `SRAM_BASE && awaddr < `SRAM_BASE + `SRAM_SIZE)
    write_zone = SRAM_ZONE;
  else if(awaddr >= `PSRAM_BASE && awaddr < `PSRAM_BASE + `PSRAM_SIZE)
    write_zone = PSRAM_ZONE;
  else if(awaddr >= `SDRAM_BASE && awaddr < `SDRAM_BASE + `SDRAM_SIZE)
    write_zone = SDRAM_ZONE;
  else if(awaddr >= `GPIO_BASE && awaddr < `GPIO_BASE + `GPIO_SIZE)begin
    write_diff_skip = 1;
    write_zone = GPIO_ZONE;
  end
  else 
    write_zone = OTHER_ZONE;
end

assign diff_skip = read_diff_skip | write_diff_skip;

always@(*)begin
  arvalid1 = 0;
  rready1 = 0;
  araddr1 = 0;
  arvalid2 = 0;
  rready2 = 0;
  araddr2 = 0;

/*`ifndef CONFIG_YSYXSOC
  arvalid3 = 0;
  rready3 = 0;
  araddr3 = 0;
`endif
*/
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
/*`ifndef CONFIG_YSYXSOC
  else if(read_zone == UART_ZONE)begin
    arvalid3 = arvalid;
    rready3 = rready;
    araddr3 = araddr;
    arready = arready3;
    rvalid = rvalid3;
    rresp = rresp3;
    rdata = rdata3;
  end
`endif*/
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
//`ifdef CONFIG_YSYXSOC
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
/*`else
  awvalid1 = 0;
  wvalid1 = 0;
  bready1 = 0;
  awaddr1 = 0;
  wdata1 = 0;
  wstrb1 = 0;
  awvalid3 = 0;
  wvalid3 = 0;
  bready3 = 0;
  awaddr3 = 0;
  wdata3 = 0;
  wstrb3 = 0;
  if(write_zone == UART_ZONE)begin
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
`endif
*/
end
endmodule
