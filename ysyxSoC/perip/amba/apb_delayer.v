module apb_delayer(
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

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

assign out_paddr = in_paddr;
assign out_psel = state == COUNTER || state == IDLE ? in_psel : 0;
assign out_penable = state == COUNTER || state == IDLE ? in_penable : 0;
assign out_pprot = state == COUNTER || state == IDLE ? in_pprot : 0;
assign out_pwrite = in_pwrite;
assign out_pwdata = in_pwdata;
assign out_pstrb = in_pstrb;

localparam IDLE = 3'b0;
localparam COUNTER = 3'b001;
localparam DELAY = 3'b010;
localparam WAIT = 3'b011;

localparam r = 16'd5;
localparam s_shift = 3'd3;
localparam COUNTER_ADD = r << s_shift;

  reg[31:0] rdata;
  reg pslverr, penable;

  reg[15:0] counter, counter_delay;
  reg[2:0] state;
  always@(posedge clock)begin
    if(reset)begin
      state <= IDLE;
      counter <= 0;
    end
    else begin
      case(state)
        IDLE:begin
          if(in_penable)begin
            state <= COUNTER;
          end
        end
        COUNTER:begin
          counter <= counter + COUNTER_ADD;
          if(out_pready)begin
            state <= DELAY;
            counter <= {3'b0, counter[15:3]};
            rdata <= out_prdata;
            pslverr = out_pslverr;
          end
        end
        DELAY:begin
          if(counter != 0)begin
            counter <= counter - 1;
          end
          else begin
            state <= WAIT;
          end
        end
        WAIT:begin
          state <= IDLE;
        end
        default:begin
        end
      endcase
    end
  end

  assign in_prdata = state == WAIT ? rdata : 0;
  assign in_pslverr = state == WAIT ? pslverr : 0;
  assign in_pready = state == WAIT ? 1 : 0;

  /*assign out_paddr   = in_paddr;
  assign out_psel    = in_psel;
  assign out_penable = in_penable;
  assign out_pprot   = in_pprot;
  assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;
  assign in_pready   = out_pready;
  assign in_prdata   = out_prdata;
  assign in_pslverr  = out_pslverr;*/

endmodule
