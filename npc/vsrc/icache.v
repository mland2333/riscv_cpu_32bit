`ifdef CONFIG_ICACHE
import "DPI-C" function void cache_miss();
import "DPI-C" function void cache_hit();
import "DPI-C" function void cache_init();
module ICACHE #(
  CACHE_OFFSET=2,
  CACHE_INDEX=4
)(
  input reset,
  input clock,
  input inst_require,
  input[31:0] pc,
  output reg inst_valid,
  output reg [31:0] inst,
  input rvalid, arready,
  output arvalid,
  output rready,
  input [31:0] rdata,
  output [31:0] araddr
);
localparam IDLE = 3'b0;
localparam REQUIRE = 3'b001;

reg _arvalid;
assign arvalid = _arvalid;

wire[31:6] tag = pc[31:6];
wire[3:0] index = pc[5:2];
reg[58:0] cache[16];

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
          if(cache[index][58] && cache[index][57:32] == tag)begin
            inst_valid <= 1;
            inst <= cache[index][31:0];
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
          state <= IDLE;
          inst_valid <= 1;
        end
      end
      default:begin
      end
    endcase
  end
end

integer i;
always@(posedge clock)begin
  if(reset)begin
    for(i=0;i<16;i=i+1)begin
      cache[i][58] = 0;
    end
  end
  else begin
    if(rvalid)begin
      cache[index] <= {1'b1, tag, rdata};
    end
  end
end

reg[31:0] _araddr;
assign araddr = _araddr;
assign rready = 1;
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

endmodule

`endif
