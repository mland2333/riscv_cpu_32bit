// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else
localparam IDLE = 3'b000; 
localparam RXTX = 3'b001;
localparam DIVI = 3'b010;
localparam SS   = 3'b011;
localparam CTRL = 3'b100;
localparam GO   = 3'b101;
localparam WAIT = 3'b110;
localparam RECV = 3'b111;

wire is_flash = (in_paddr >= flash_addr_start & in_paddr <= flash_addr_end) & in_penable;

wire[31:0] rdata, flash_rdata;
reg[31:0] flash_wdata;
reg[4:0] flash_addr;
reg[2:0] state;
reg is_write, is_ready;
always@(posedge clock)begin
  if(reset)begin
    state <= IDLE;
  end
  else begin
    is_write <= 1;
    is_ready <= 0;
    case(state)
      IDLE:begin
        if(pready && is_flash)begin
          state <= RXTX;
          flash_wdata <= {8'h03, in_paddr[23:0]};
          flash_addr <= 5'b00100;
        end
      end
      RXTX:begin
        flash_wdata <= 32'h2;
        flash_addr <= 5'b10100;
        state <= DIVI;
      end
      DIVI:begin
        flash_wdata <= 32'h1;
        flash_addr <= 5'b11000;
        state <= SS;
      end
      SS:begin
        flash_wdata <= 32'h2040;
        flash_addr <= 5'b10000;
        state <= CTRL;
      end
      CTRL:begin
        flash_wdata <= 32'h2140;
        flash_addr <= 5'b10000;
        state <= GO;
      end
      GO:begin
        if(is_write)begin
          flash_addr <= 5'b10000;
          is_write <= 0;
        end
        else begin
          is_write <= 0;
          state <= WAIT;
        end
      end
      WAIT:begin
        if(prdata[8] == 0)begin
          state <= RECV;
          flash_addr <= 5'b00000;
          is_write <= 0;
        end
        else begin
          is_write <= 0;
        end
      end
      RECV:begin
        state <= IDLE;
        is_ready <= 1;
      end
    endcase
  end
end

assign flash_rdata = {prdata[7:0], prdata[15:8], prdata[23:16], prdata[31:24]};
wire pready;

wire [4:0] praddr = is_flash ? flash_addr : in_paddr[4:0];
wire [31:0] pwdata = is_flash ? flash_wdata : in_pwdata;
wire pwrite = is_flash ? is_write : in_pwrite;
assign in_pready = is_flash ? is_ready : pready;
wire[3:0] pstrb = is_flash ? 4'hf : in_pstrb;
wire psel = is_flash ? 1'b1 : in_psel;
wire penable = is_flash ? 1'b1 : in_penable;
wire[31:0] prdata;
assign in_prdata = is_flash ? flash_rdata : prdata;

spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(praddr),
  .wb_dat_i(pwdata),
  .wb_dat_o(prdata),
  .wb_sel_i(pstrb),
  .wb_we_i (pwrite),
  .wb_stb_i(psel),
  .wb_cyc_i(penable),
  .wb_ack_o(pready),
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

`endif // FAST_FLASH

endmodule
