module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq,
  input        en
);
localparam CMD_W             = 4;
localparam CMD_NOP           = 4'b0111;
localparam CMD_ACTIVE        = 4'b0011;
localparam CMD_READ          = 4'b0101;
localparam CMD_WRITE         = 4'b0100;
localparam CMD_TERMINATE     = 4'b0110;
localparam CMD_PRECHARGE     = 4'b0010;
localparam CMD_REFRESH       = 4'b0001;
localparam CMD_LOAD_MODE     = 4'b0000;

localparam STATE_INIT        = 4'd0;
localparam STATE_DELAY       = 4'd1;
localparam STATE_IDLE        = 4'd2;
localparam STATE_ACTIVATE    = 4'd3;
localparam STATE_READ        = 4'd4;
localparam STATE_READ_WAIT   = 4'd5;
localparam STATE_WRITE      = 4'd6;
localparam STATE_WRITE1      = 4'd7;
localparam STATE_PRECHARGE   = 4'd8;
localparam STATE_REFRESH     = 4'd9;

  reg[8191:0] sdram0[8192];
  reg[8191:0] sdram1[8192];
  reg[8191:0] sdram2[8192];
  reg[8191:0] sdram3[8192];
  reg[8191:0] sdram_row[4];
  reg[1:0]  sdram_index;
  reg[15:0] row[4][512];
  //reg[15:0] row1[512];
  //reg[15:0] row2[512];
  //reg[15:0] row3[512];
  reg[15:0] rdata, wdata, _wdata;
  reg[12:0] addr_row[4], addr_col;
  reg[3:0] state;
  reg[12:0] mode;
  wire [3:0] cmd0 = {cs, ras, cas, we};
  wire [3:0] cmd = en ? cmd0 : (cmd0 == CMD_ACTIVE || cmd0 == CMD_PRECHARGE ? cmd0 : 4'd7);
  reg[2:0] counter;
  reg[1:0] wmask;

  wire[2:0] burst_length = 3'd4;
  wire[2:0] burst_num = 3'd1;
  wire[2:0] read_delay = 3'd2;

  always@(posedge clk)begin
    if(cke)begin
      case(cmd)
        CMD_NOP:begin
          if(state == STATE_READ || state == STATE_WRITE || state == STATE_ACTIVATE
             || state == STATE_PRECHARGE)begin
            if(counter != 0) counter <= counter - 1;
            else state <= STATE_INIT;
          end
          else
            state <= STATE_INIT;
        end
        CMD_ACTIVE:begin
          state <= STATE_ACTIVATE;
          counter <= 3'b001;
          addr_row[ba] <= a;
          sdram_index <= ba;
        end
        CMD_READ:begin
          state <= STATE_READ;
          counter <= burst_num + read_delay - 1;
          addr_col <= a;
          sdram_index <= ba;
        end
        CMD_WRITE:begin
          state <= STATE_WRITE;
          counter <= burst_num - 1;
          addr_col <= a;
          _wdata <= dq;
          wmask <= dqm;
          sdram_index <= ba;
        end
        CMD_PRECHARGE:begin
          state <= STATE_PRECHARGE;
          counter <= 3'b001;
          //sdram_index <= ba;
        end
        default:begin
        end
      endcase
    end
  end
 
  wire[15:0] now_data = row[sdram_index][addr_col[8:0]];
  wire[15:0]  wdata00 = _wdata,
              wdata01 = {_wdata[15:8], 8'd0} | {8'd0, now_data[7:0]},
              wdata10 = {8'd0, _wdata[7:0]} | {now_data[15:8], 8'd0},
              wdata11 = now_data;

  always@(*)begin
    case(wmask)
      2'd0: wdata = wdata00;
      2'd1: wdata = wdata01;
      2'd2: wdata = wdata10;
      2'd3: wdata = wdata11;
    endcase
  end

  integer i;
  always@(posedge clk)begin
    case(state)
      STATE_INIT:begin
      end
      STATE_ACTIVATE:begin
        if(counter == 1)begin
          case(sdram_index)
            2'd0: sdram_row[0] <= sdram0[addr_row[0]];
            2'd1: sdram_row[1] <= sdram1[addr_row[1]];
            2'd2: sdram_row[2] <= sdram2[addr_row[2]];
            2'd3: sdram_row[3] <= sdram3[addr_row[3]];
          endcase
        end
        else if(counter == 0)begin
          for (i = 0; i < 512; i = i + 1) begin
            row[sdram_index][i] <= sdram_row[sdram_index][i*16 +: 16];
          end
        end
      end
      STATE_READ:begin
        if(counter > 3'd1) begin
          rdata <= row[sdram_index][addr_col[8:0]];
          addr_col <= addr_col + 1;
        end
      end
      STATE_WRITE:begin
        if(counter != 3'd0) begin
          row[sdram_index][addr_col[8:0]] <= wdata;
          _wdata <= dq;
          wmask <= dqm;
          addr_col <= addr_col + 1;
        end
        else if(counter == 3'd0) begin
          row[sdram_index][addr_col[8:0]] <= wdata;
        end
      end
      STATE_PRECHARGE:begin
        if(counter == 1)begin
          for (i = 0; i < 512; i = i + 1) begin
            sdram_row[0][i*16 +: 16] <= row[0][i];
            sdram_row[1][i*16 +: 16] <= row[1][i];
            sdram_row[2][i*16 +: 16] <= row[2][i];
            sdram_row[3][i*16 +: 16] <= row[3][i];
          end
        end
        else if(counter == 0)begin
            sdram0[addr_row[0]] <= sdram_row[0];
            sdram1[addr_row[1]] <= sdram_row[1];
            sdram2[addr_row[2]] <= sdram_row[2];
            sdram3[addr_row[3]] <= sdram_row[3];
        end
      end
      default:begin
      end
    endcase
  end
  assign dq = state == STATE_READ ? rdata : 16'bz;

endmodule
