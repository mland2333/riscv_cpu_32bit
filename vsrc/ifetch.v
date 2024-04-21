module IFU(
  input clk, pc_valid,
  input [31:0] pc,
  output reg[31:0] inst,
  output reg pc_wen
);
//localparam IDLE = 2'b01;
//localparam WATI_READY = 2'b10;

//reg[1:0] state;

always@(posedge clk)begin
  pc_wen <= pc_valid;
end

always@(*)begin
  if(pc_valid)begin
    inst = pmem_read(pc);
    //$display("inst = %h\n", inst);
  end
  else begin
    inst = 32'b0;
  end
end

/*MemFile imem(.raddr(pc[7:0]), .waddr(0), .wdata(0), .wen(0), .rdata(inst));*/
/*always@(posedge clk)begin
  if(rst) state <= IDLE;
  else begin*/

/*always@(posedge clk)begin
  if(rst) state <= IDLE;
  else begin
    case(state)
      IDLE:begin
        if(pc_valid)begin
          state <= WATI_READY;
        end
        else begin
          state <= IDLE;
        end
      end
      WATI_READY:begin
        if(idu_ready)begin
          state <= IDLE;
          ifu_valid <= 1;
        end
        else begin
          state <= WATI_READY;
          ifu_ready <= 0;
        end
      end
      default:state <= IDLE;
    endcase
  end
end*/
endmodule
