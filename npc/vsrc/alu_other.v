/*module Adder_4bit(
  input[3:0] a, b,
  input cin,
  output[3:0] s,
  output cout
);
  wire [3:0]p = a | b;
  wire [3:0]g = a & b;
  wire [3:0]c;
  assign c[0] = cin;
  assign c[1] = g[0] | p[0]&cin;
  assign c[2] = g[1] | p[1]&g[0] | p[1]&p[0]&cin;
  assign c[3] = g[2] | p[2]&g[1] | p[2]&p[1]&g[0] | p[2]&p[1]&p[0]&c[0];
  assign cout = g[3] | p[3]&g[2] | p[3]&p[2]&g[1] | p[3]&p[2]&p[1]&g[0] | p[3]&p[2]&p[1]&p[0]&cin;
  assign s = a ^ b ^ c;
endmodule
*/

/*
module Adder_8bit(
  input[7:0] a, b,
  input cin,
  output[7:0] s,
  output cout
);
  wire [7:0]p = a | b;
  wire [7:0]g = a & b;
  wire c0 = cin;
  wire c1 = g[0] | p[0]&cin;
  wire c2 = g[1] | p[1]&g[0] | p[1]&p[0]&cin;
  wire c3 = g[2] | p[2]&g[1] | p[2]&p[1]&g[0] | p[2]&p[1]&p[0]&cin;
  wire c4 = g[3] | p[3]&g[2] | p[3]&p[2]&g[1] | p[3]&p[2]&p[1]&g[0] | p[3]&p[2]&p[1]&p[0]&cin;
  wire c5 = g[4] | p[4]&g[3] | p[4]&p[3]&g[2] | p[4]&p[3]&p[2]&g[1] | p[4]&p[3]&p[2]&p[1]&g[0] | p[4]&p[3]&p[2]&p[1]&p[0]&cin;
  wire c6 = g[5] | p[5]&g[4] | p[5]&p[4]&g[3] | p[5]&p[4]&p[3]&g[2] | p[5]&p[4]&p[3]&p[2]&g[1] | p[5]&p[4]&p[3]&p[2]&p[1]&g[0] | p[5]&p[4]&p[3]&p[2]&p[1]&p[0]&cin;
  wire c7 = g[6] | p[6]&g[5] | p[6]&p[5]&g[4] | p[6]&p[5]&p[4]&g[3] | p[6]&p[5]&p[4]&p[3]&g[2] | p[6]&p[5]&p[4]&p[3]&p[2]&g[1] | p[6]&p[5]&p[4]&p[3]&p[2]&p[1]&g[0] | p[6]&p[5]&p[4]&p[3]&p[2]&p[1]&p[0]&cin;
  assign cout = g[7] | p[7]&g[6] | p[7]&p[6]&g[5] | p[6]&p[5]&p[7]&g[4] | p[6]&p[5]&p[4]&p[7]&g[3] | p[6]&p[5]&p[4]&p[3]&p[7]&g[2] | p[6]&p[5]&p[4]&p[3]&p[2]&p[7]&g[1] | p[6]&p[5]&p[4]&p[3]&p[2]&p[1]&p[7]&g[0] | p[6]&p[5]&p[4]&p[3]&p[2]&p[1]&p[7]&p[0]&cin;

  wire[7:0] c = {c7, c6, c5, c4, c3, c2, c1, c0};
  assign s = a ^ b ^ c;
endmodule

module Adder_32bit(
    input [31:0]a, b,
    input cin,
    output [31:0]result,
    output cout
);

  wire[4:0] c;
  assign c[0] = cin;
  Adder_8bit add0(
        .a(a[7:0]),
        .b(b[7:0]),
        .cin(c[0]),
        .s(result[7:0]),
        .cout(c[1])
      );
  Adder_8bit add1(
        .a(a[15:8]),
        .b(b[15:8]),
        .cin(c[1]),
        .s(result[15:8]),
        .cout(c[2])
  );
  Adder_8bit add2(
        .a(a[23:16]),
        .b(b[23:16]),
        .cin(c[2]),
        .s(result[23:16]),
        .cout(c[3])
  );
  Adder_8bit add3(
        .a(a[31:24]),
        .b(b[31:24]),
        .cin(c[3]),
        .s(result[31:24]),
        .cout(c[4])
  );

  assign cout = c[4];
endmodule
*/
