`ifdef CONFIG_ICACHE
import "DPI-C" function void cache_miss();
import "DPI-C" function void cache_hit();
import "DPI-C" function void cache_init();
module ICACHE #(
  ICACHE_SIZE=1,
  ICACHE_NUMS=16
)(
  input reset,
  input clock,
  input inst_require,
  input[31:0] pc,
  output reg inst_valid,
  output reg [31:0] inst,
  input rvalid, arready,
  output arvalid,
  output reg rready,
  input [31:0] rdata,
  output [31:0] araddr

);
localparam IDLE = 3'b0;
localparam REQUIRE = 3'b001;


`define TAG 31 : $clog2(ICACHE_SIZE*ICACHE_NUMS) + 2
localparam TAG_SIZE = (32 - $clog2(ICACHE_SIZE*ICACHE_NUMS) - 2);

`define INDEX $clog2(ICACHE_SIZE*ICACHE_NUMS) + 2 - 1: $clog2(ICACHE_SIZE) + 2
localparam INDEX_SIZE = $clog2(ICACHE_NUMS);

localparam ICACHE_LINE = 32*ICACHE_SIZE + TAG_SIZE + 1;
localparam VALID = ICACHE_LINE - 1;

`define ICACHE_TAG VALID - 1 : 32*ICACHE_SIZE

reg _arvalid;
assign arvalid = _arvalid;

wire[TAG_SIZE-1 : 0] tag = pc[`TAG];
wire[INDEX_SIZE - 1 : 0] index = pc[`INDEX];

reg[ICACHE_LINE - 1:0] icache[ICACHE_NUMS];

integer i;

`ifdef CONFIG_BURST
wire[31:0] insts[ICACHE_SIZE];
always@ * begin
  for(i = 0; i< ICACHE_SIZE; i=i+1)begin
    insts[i] = icache[index][32*i +: 32];
  end
end

`else
reg[2:0] state;
reg need_read;
always@(posedge clock)begin
  if(reset)begin
    state <= IDLE;
    inst_valid <= 0;
    need_read <= 0;
    _araddr <= 0;
    cache_init();
  end
  else begin
    case(state)
      IDLE:begin
        inst_valid <= 0;
        if(inst_require)begin
          _araddr <= pc;
          if(icache[index][VALID] && icache[index][`ICACHE_TAG] == tag)begin
            inst_valid <= 1;
            inst <= icache[index][31:0];
            cache_hit();
          end
          else begin
            need_read <= 1;
            state <= REQUIRE;
            cache_miss();
            //$display("%h", pc);
          end
        end
      end
      REQUIRE:begin
        need_read <= 0;
        if(rready)begin
          rready <= 0;
          state <= IDLE;
          inst_valid <= 0;
        end
        else if(rvalid)begin
          rready <= 1;
          inst <= rdata;
          inst_valid <= 1;
        end
      end
      default:begin
      end
    endcase
  end
end

always@(posedge clock)begin
  if(reset)begin
    for(i=0;i<16;i=i+1)begin
      icache[i][VALID] = 0;
    end
  end
  else begin
    if(rvalid)begin
      icache[index] <= {1'b1, tag, rdata};
    end
  end
end

reg[31:0] _araddr;
assign araddr = _araddr;
//assign rready = 1;
always@(posedge clock)begin
  if(reset)begin
    _arvalid <= 0;
  end
  else begin
    if(need_read && ~arvalid)begin
      _arvalid <= 1;
    end
    else if(arvalid && arready)
      _arvalid <= 0;
  end
end
`endif

endmodule

`endif
