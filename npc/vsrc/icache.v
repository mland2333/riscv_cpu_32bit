`ifdef CONFIG_ICACHE
module ICACHE(
  input reset,
  input clock,
  input inst_require,
  input[31:0] pc,
  output reg inst_valid,
  output reg [31:0] inst,
  input rvalid, arready,
  output reg arvalid,
  output rready,
  input [31:0] rdata,
  output [31:0] araddr
);
localparam IDLE = 3'b0;
localparam REQUIRE = 3'b001;
localparam READY = 3'b010;

wire[25:0] tag = pc[31:6];
wire[3:0] index = pc[5:2];
reg[58:0] cache[16];
assign inst = cache[index][31:0];

reg[2:0] state;
reg need_read;
always@(posedge clock)begin
  if(reset)begin
    state <= IDLE;
    inst_valid <= 0;
    need_read <= 0;
  end
  else begin
    case(state)
      IDLE:begin
        inst_valid <= 0;
        if(inst_require)begin
          if(cache[index][58] && cache[index][57:32] == tag)
            inst_valid <= 1;
          else begin
            need_read <= 1;
            state <= REQUIRE;
          end
        end
      end
      REQUIRE:begin
        need_read <= 0;
        if(rvalid)begin
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
    if(rvalid)
      cache[index] <= {1'b1, tag, rdata};
  end
end

reg _arvalid;
assign araddr = pc;
assign arvalid = _arvalid;
assign rready = 1;
always@(posedge clock)begin
  if(reset)begin
    _arvalid <= 0;
  end
  else begin
      if(need_read && ~arvalid)
        _arvalid <= 1;
      else if(arvalid && arready)
        _arvalid <= 0;
  end
end

endmodule

`endif
