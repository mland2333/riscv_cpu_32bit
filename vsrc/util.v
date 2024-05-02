module COUNT(
  input clk, rst, start,
  input[7:0] count,
  output zero
);

reg[7:0] _count;

reg state;

always@(posedge clk)begin
  if(rst)begin
    state <= 0;
    _count <= 7'b0;
    zero <= 0;
  end
  else if(start && state)begin
    if(_count == 0)begin
      state <= 0;
      zero <= 1;
    end
    else begin
      _count <= _count - 1;
    end
  end
  else if(start)begin
    state <= 1;
    _count <= count;
    zero <= 0;
  end
  else begin
    state <= 0;
    _count <= 0;
    zero <= 0;
  end
end


endmodule
