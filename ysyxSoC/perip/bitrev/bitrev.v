module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);
  localparam IDLE = 2'b00;
  localparam RECV = 2'b01;
  localparam TRAN = 2'b10;
  localparam SEND = 2'b11;
  reg [7:0]temp;
  reg[1:0] state;
  reg[2:0] nums, nums1;
  reg active, flag;
  always@(posedge sck)begin
    if(ss)begin
      state <= IDLE;
      temp <= 0 ;
    end
    else begin
      case(state)
        IDLE:begin
          temp[0] <= mosi;
          nums <= 3'h7;
          state <= RECV;
          active <= 1;
        end
        RECV:begin
          temp <= temp << 1 | {7'b0, mosi};
          if(nums == 1)begin
            state <= TRAN;
            nums1 <= 3'h7;
          end
          else begin
            nums <= nums - 1;
          end
        end
        TRAN:begin
          state <= SEND;
          //nums1 <= nums1 - 1;
        end
        SEND:begin
          temp <= temp >> 1;
          if(nums1 == 1)begin
            state <= IDLE;
            active <= 0;
          end
          else begin
            nums1 <= nums1 - 1;
          end
        end
        default:begin
        end
      endcase
    end
  end
  always@(negedge sck)begin
    flag <= active;
  end

  assign miso = active|flag ? temp[0] : 1'b1;
endmodule
