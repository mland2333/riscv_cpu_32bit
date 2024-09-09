/*
`ifdef CONFIG_ICACHE
import "DPI-C" function void cache_miss();
import "DPI-C" function void cache_hit();
import "DPI-C" function void cache_init();
*/
module ICACHE #(
  ICACHE_SIZE=4,
  ICACHE_NUMS=4
)(
  input reset,
  input clock,
  input inst_require,
  input[31:0] pc,
  input fencei, ctrl_valid,
  output reg inst_valid,
  output reg [31:0] inst,
  input rvalid, arready,
  output reg arvalid,
  output rready,
  input [31:0] rdata,

  output [31:0] araddr
//  `ifdef CONFIG_BURST
    ,
  output[7:0] arlen,
  output[2:0] arsize,
  output[1:0] arburst,
  input rlast
//  `endif
);
localparam IDLE = 3'b0;
localparam REQUIRE = 3'b001;
localparam BURST = 3'b010;
localparam READY = 3'b011;

`define TAG 31 : $clog2(ICACHE_SIZE*ICACHE_NUMS) + 2
localparam TAG_SIZE = (32 - $clog2(ICACHE_SIZE*ICACHE_NUMS) - 2);

`define INDEX $clog2(ICACHE_SIZE*ICACHE_NUMS) + 2 - 1: $clog2(ICACHE_SIZE) + 2
localparam INDEX_SIZE = $clog2(ICACHE_NUMS);

localparam ICACHE_LINE = 32*ICACHE_SIZE + TAG_SIZE + 1;
localparam VALID = ICACHE_LINE - 1;
`define ICACHE_TAG VALID - 1 : 32*ICACHE_SIZE

assign rready = 1;
wire[TAG_SIZE-1 : 0] tag = _pc[`TAG];
wire[INDEX_SIZE - 1 : 0] index = _pc[`INDEX];

reg[ICACHE_LINE - 1:0] icache[ICACHE_NUMS];
reg refresh;

integer i;

//`ifdef CONFIG_BURST
localparam OFFEST_SIZE = $clog2(ICACHE_SIZE);
`define OFFEST OFFEST_SIZE + 1 : 2

reg[31:0] insts[ICACHE_SIZE];

assign arlen = 8'b011;
assign arsize = 3'b010;
assign arburst = 2'b01;

always@ * begin
  for(i = 0; i<ICACHE_SIZE; i=i+1)begin
    insts[i] = icache[index][32*i +: 32];
  end
end

wire[OFFEST_SIZE + 1 : 0] zero = 0;
assign araddr = {_pc[31: OFFEST_SIZE + 2], zero};

reg[2:0] state;
wire[OFFEST_SIZE-1 : 0] offest = _pc[`OFFEST];
wire need_read = ~(icache[index][VALID] && icache[index][`ICACHE_TAG] == tag);

reg[31:0] _pc;
always@(posedge clock)begin
  if(inst_require) _pc <= pc;
end

reg[7:0] burst_nums;
reg trans_ready;
always@(posedge clock)begin
  if(reset) state <= IDLE;
  else begin
    case(state)
      IDLE:begin
        if(inst_require) state <= REQUIRE;
      end
      REQUIRE:begin
        if(need_read) state <= BURST;
        else state <= IDLE;
      end
      BURST:begin
        if(burst_nums == ICACHE_SIZE) state <= READY;
      end
      READY:begin
        state <= IDLE;
      end
      default: begin
        state <= IDLE;
      end
    endcase
  end
end

always@(posedge clock)begin
  if(reset)begin
    //cache_init();
    inst <= 0;
  end
  else begin
    if(inst_require && !need_read)begin
      //cache_hit();
      inst <= insts[offest];
    end
    else if(burst_nums == ICACHE_SIZE)begin
      //cache_miss();
      inst <= insts[offest];
    end
  end
end

always@(posedge clock)begin
  if(reset) inst_valid <= 0;
  else begin
    if(inst_require && !need_read)
      inst_valid <= 1;
    else if(burst_nums == ICACHE_SIZE)
      inst_valid <= 1;
    else inst_valid <= 0;
  end
end

always@(posedge clock)begin
  if(reset)begin
    arvalid <= 0;
  end
  else begin
    if(inst_require && need_read && !arvalid) arvalid <= 1;
    else if(arvalid && arready) arvalid <= 0;
  end
end

always@(posedge clock)begin
  if(reset) burst_nums <= 0;
  else begin
    if(burst_nums == ICACHE_SIZE) burst_nums <= 0;
    else if(_rvalid) burst_nums <= burst_nums + 1;
  end
end

reg _rvalid;
reg[31:0] _rdata;
always@(posedge clock)begin
    _rvalid <= rvalid;
    if(rvalid) _rdata <= rdata;
end

always@(posedge clock)begin
  if(reset)begin
    for(i=0; i<ICACHE_NUMS; i++)begin
      icache[i][VALID] <= 0;
    end
  end
  else begin
    if(_rvalid) icache[index][32*burst_nums +: 32] <= _rdata;
    if(rlast) begin
      icache[index][VALID] <= 1;
      icache[index][`ICACHE_TAG] <= tag;
    end
    else if(ctrl_valid && fencei)begin
      for(i=0; i<ICACHE_NUMS; i++)begin
        icache[i][VALID] <= 0;
      end
    end
  end
end

/*`else
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
        if(rvalid)begin
          inst <= rdata;
          inst_valid <= 1;
          state <= IDLE;
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

always@(posedge clock)begin
  if(reset)begin
    arvalid <= 0;
  end
  else begin
    if(need_read && ~arvalid)begin
      arvalid <= 1;
    end
    else if(arvalid && arready)
      arvalid <= 0;
  end
end
`endif*/
endmodule

//`endif
