module IFU(
  input valid,
  input [31:0] pc,
  output reg[31:0] inst
);
always@(*)begin
  if(valid)
    inst = pmem_read(pc);
  else
    inst = 0;
end


endmodule
