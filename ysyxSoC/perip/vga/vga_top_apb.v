module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);

wire [23:0] vga_data;
reg[23:0] buffer[524287:0];
wire[23:0] wdata = in_pwdata[23:0];
wire[18:0] addr = in_paddr[20:2];

reg ready;
assign in_pready = ready;
always@(posedge clock)begin
  if(reset)
    ready <= 0;
  else if(in_penable && !ready)
    ready <= 1;
  else if(ready)
    ready <= 0;
end


always@(posedge clock)begin
  if(in_penable)begin
    if(in_pwrite)begin
      buffer[addr] <= wdata;
    end
  end
end

parameter h_frontporch = 96;
parameter h_active = 144;
parameter h_backporch = 784;
parameter h_total = 800;

parameter v_frontporch = 2;
parameter v_active = 35;
parameter v_backporch = 515;
parameter v_total = 525;

reg [9:0] x_cnt;
reg [9:0] y_cnt;
wire h_valid;
wire v_valid;

always @(posedge clock) begin
    if(reset) begin
        x_cnt <= 1;
        y_cnt <= 1;
    end
    else begin
        if(x_cnt == h_total)begin
            x_cnt <= 1;
            if(y_cnt == v_total) y_cnt <= 1;
            else y_cnt <= y_cnt + 1;
        end
        else x_cnt <= x_cnt + 1;
    end
end

//生成同步信号    
assign vga_hsync = (x_cnt > h_frontporch);
assign vga_vsync = (y_cnt > v_frontporch);
//生成消隐信号
assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
assign vga_valid = h_valid & v_valid;
//计算当前有效像素坐标
wire[9:0] h_addr = h_valid ? (x_cnt - 10'd145) : 10'd0;
wire[9:0] v_addr = v_valid ? (y_cnt - 10'd36) : 10'd0;
wire [18:0] data_addr = {h_addr, 9'b0} + {2'b0, h_addr, 7'b0} + {9'b0, v_addr};
//设置输出的颜色值
assign vga_data = buffer[data_addr];
assign {vga_r, vga_g, vga_b} = vga_data;

endmodule
