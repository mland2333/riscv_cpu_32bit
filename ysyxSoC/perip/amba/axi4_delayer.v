module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);
  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  assign out_rready = in_rready;
  assign in_rid = out_rid;
  assign in_rresp = out_rresp;
  reg[31:0] rdata_buffer[8];
  localparam IDLE = 3'b0;
  localparam COUNTER = 3'b001;
  localparam DELAY = 3'b010;
  localparam WAIT = 3'b011;

  localparam r = 32'd5;
  localparam s_shift = 3'd3;
  localparam COUNTER_ADD = r << s_shift;

  reg[31:0] rcounter;
  reg[31:0] rcounter_delay[8];
  reg[7:0] tasks;
  reg[2:0]tasks_end, free_begin;
  reg[2:0] rstate;
  reg rlast;
  always@(posedge clock)begin
    if(reset)begin
      rstate <= IDLE;
      rcounter <= 0;
      free_begin <= 0;
    end
    else begin
      case(rstate)
        IDLE:begin
          free_begin <= 0;
          tasks_end <= 0;
          rcounter <= 0;
          rlast <= 0;
          if(in_arvalid)begin
            rstate <= COUNTER;
          end
        end
        COUNTER:begin
          rcounter <= rcounter + COUNTER_ADD;
          if(out_rvalid)begin
            rcounter_delay[free_begin] <= {3'b0, rcounter[31:3]};
            free_begin <= free_begin + 1;
            rdata_buffer[free_begin] <= out_rdata;
            tasks[free_begin] <= 1;
            tasks_end <= free_begin;
          end
          else if(tasks[tasks_end]==1
            && rcounter_delay[tasks_end]==0)begin
            rstate <= IDLE;
            rlast <= 1;
          end
        end
        default:begin
        end
      endcase
    end
  end
    integer i;
    reg rvalid;
    reg[7:0] ready;
    always@(posedge clock)begin
      rvalid <= 0;
      for(i=0; i<8; i++)begin
        if(tasks[i]==1 && rcounter_delay[i]==0)begin
          tasks[i] <= 0;
          rvalid <= 1;
          ready[i] <= 1;
        end
        else if(tasks[i]==1)begin
          rcounter_delay[i] = rcounter_delay[i] - 1;
        end
        else 
          ready[i] <= 0;
      end
  end
  assign in_rvalid = rvalid;
  assign in_rdata =
         ready[0]==1?rdata_buffer[0]
        :ready[1]==1?rdata_buffer[1]
        :ready[2]==1?rdata_buffer[2]
        :ready[3]==1?rdata_buffer[3]
        :ready[4]==1?rdata_buffer[4]
        :ready[5]==1?rdata_buffer[5]
        :ready[6]==1?rdata_buffer[6]
        :ready[7]==1?rdata_buffer[7]
        : 0;
  assign in_rlast = rlast;

  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  assign out_bready = in_bready;
  assign in_bid = out_bid;
  assign in_bresp = out_bresp;
  assign in_awready = out_awready;
  assign in_wready = out_wready;
  reg[31:0] wcounter;
  reg[2:0] wstate;
  reg wtask;
  always@(posedge clock)begin
    if(reset)begin
      wstate <= IDLE;
      wcounter <= 0;
      wtask <= 0;
    end
    else begin
      case(wstate)
        IDLE:begin
          wcounter <= 0;
          if(in_awvalid)begin
            wstate <= COUNTER;
          end
        end
        COUNTER:begin
          wcounter <= wcounter + COUNTER_ADD;
          if(out_bvalid)begin
            wcounter <= {3'b0, wcounter[31:3]};
            wtask <= 1;
          end
          else if(wtask == 1 && wcounter==0)begin
            wstate <= IDLE;
          end
        end
        default:begin
        end
      endcase
    end
  end

  reg bvalid;
  always@(posedge clock)begin
    bvalid <= 0;
    if(wtask && wcounter == 0)begin
      wtask <= 0;
      bvalid <= 1;
    end
    else if(wtask)
      wcounter <= wcounter - 1;
  end
  assign in_bvalid = bvalid;
  /*assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  assign out_rready = in_rready;
  assign in_rvalid = out_rvalid;
  assign in_rid = out_rid;
  assign in_rdata = out_rdata;
  assign in_rresp = out_rresp;
  assign in_rlast = out_rlast;
  assign in_awready = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign in_wready = out_wready;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  assign out_bready = in_bready;
  assign in_bvalid = out_bvalid;
  assign in_bid = out_bid;
  assign in_bresp = out_bresp;*/

endmodule
