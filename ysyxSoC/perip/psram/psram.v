import "DPI-C" function int psram_read(input int addr);
import "DPI-C" function void psram_write(input int addr, input int data);

module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);
  typedef enum [2:0] { mode_t, qpi_t, cmd_t, addr_t, delay_t, read_t, write_t, err_t } state_t;
  reg[7:0] psram[2**24];
  wire reset = ce_n;
  reg[7:0] counter;
  reg[2:0] state;
  reg[31:0] rdata, wdata;
  reg[7:0] cmd;
  reg[23:0] addr;
  always@(posedge sck or posedge reset) begin
    if (reset) state <= mode_t;
    else begin
      case (state)
        mode_t:  state <= (counter == 8'd1 ) ? (dio == 4'b0001 ? qpi_t : cmd_t) : state; 
        cmd_t:  state <= (counter == 8'd7 ) ? addr_t : state;
        qpi_t:  state <= (counter == 8'd1) ? addr_t : state;
        addr_t: state <= (counter == 8'd5) ? (cmd == 8'heb ? delay_t : cmd == 8'h38 ? write_t : err_t): state;
        delay_t: state <= (counter == 8'd5) ? read_t : state;
        read_t: state <= state;
        write_t: state <= state;
        default: begin
          state <= state;
          $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh`, only support `03h` read command\n", cmd);
          $fatal;
        end
      endcase
    end
  end

  always@(posedge sck or posedge reset) begin
    if (reset) counter <= 8'd0;
    else begin
      case (state)
        mode_t:  counter <= (counter < 8'd1 ) ? counter + 8'd1 : 8'd0;
        cmd_t:   counter <= (counter < 8'd7 ) ? counter + 8'd1 : 8'd0;
        qpi_t:   counter <= (counter < 8'd1 ) ? counter + 8'd1 : 8'd0;
        addr_t:  counter <= (counter < 8'd5 ) ? counter + 8'd1 : 8'd0;
        delay_t: counter <= (counter < 8'd5 ) ? counter + 8'b1 : 8'd0;
        default: counter <= counter + 8'd1;
      endcase
    end
  end

  always@(posedge sck or posedge reset) begin
    if (reset)               cmd <= 8'd0;
    else if (state == cmd_t) cmd <= { cmd[6:0], dio[0]};
    else if (state == qpi_t) cmd <= { cmd[3:0], dio};
  end

  always@(posedge sck or posedge reset) begin
    if (reset) addr <= 24'd0;
    else if (state == addr_t)
      addr <= { addr[19:0], dio };
  end
  reg wen;

  always@(posedge sck or posedge reset)begin
    if(reset) wen <= 0;
    else if(state == write_t && counter == 8'd7)
      wen <= 1;
    else wen <= 0;
  end
  wire[31:0] bswap_wdata = {wdata[27:24], wdata[31:28], wdata[19:16], wdata[23:20], wdata[11:8], wdata[15:12], wdata[3:0], wdata[7:4]};
  always@(posedge sck or posedge reset) begin
    if (reset) begin
      if(state == write_t)begin
        if(counter == 8'd8)begin
          psram[{addr[23:2], 2'b00}] <= bswap_wdata[7:0];
          psram[{addr[23:2], 2'b01}] <= bswap_wdata[15:8];
          psram[{addr[23:2], 2'b10}] <= bswap_wdata[23:16];
          psram[{addr[23:2], 2'b11}] <= bswap_wdata[31:24];
        end
        else if(counter == 8'd4)begin
          psram[{addr[23:1], 1'b0}] <= bswap_wdata[23:16];
          psram[{addr[23:1], 1'b1}] <= bswap_wdata[31:24];
        end
        else if(counter == 8'd2)begin
          psram[addr] <= bswap_wdata[31:24];
        end
      end
      wdata <= 32'd0;
    end
    else if (state == write_t) begin
      wdata <= { dio, wdata[31:4] };
    end
  end

  reg[31:0] data;
  wire[31:0] bswap_rdata = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
  always@(posedge sck or posedge reset) begin
    if (reset) data <= 32'd0;
    else if (state == read_t) begin
      if(counter == 8'd0)begin
        rdata[7:0]   <= psram[{addr[23:2], 2'b00}];
        rdata[15:8]  <= psram[{addr[23:2], 2'b01}];
        rdata[23:16] <= psram[{addr[23:2], 2'b10}];
        rdata[31:24] <= psram[{addr[23:2], 2'b11}];
      end
      else if(counter >= 8'd1)
        data <= { { counter == 8'd1 ? bswap_rdata : data}[27:0], 4'b0};
    end
  end

  assign dio = ce_n ? 4'hf : (state == read_t && counter == 8'b1 ? bswap_rdata[31:28] : data[31:28]);

endmodule
