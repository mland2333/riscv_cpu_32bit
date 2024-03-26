/*module Adder_1bit(
    input a, b, cin,
    output result, cout
);
    wire sum;
    assign sum = a ^ b;
    assign result = sum ^ cin;
    assign cout = a & b | sum & cin; 
endmodule
*/

/*module Adder_4bit(
    input [3:0]a, b,
    input cin,
    output [3:0]result
);
    wire [3:0] p, g, ci;
    pg_generate mypg(.a(a), .b(b), .p(p), .g(g));
    c_generate myc(.p(p), .g(g), .cin(cin), .cout(ci));
    assign result = p ^ ci;
endmodule
*/

/*module Adder_16bit(
    input [15:0]a, b,
    input cin,
    output [15:0]result
);
    wire [15:0] p, g, ci;
    wire [3:0] pm, gm;
    wire [4:0] cm;
    assign cm[0] = cin;
    generate
        genvar i;
        for(i = 0; i< 4; i++)begin
            //Adder_4bit myadd(.a(a[i*4+3: i*4]), .b(i*4+3: i*4), ,cin(cm[i]), .result(result[i*4+3: i*4]));
            pg_generate mypg(.a(a[i*4+3: i*4]), .b(b[i*4+3: i*4]), .p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]));
            c_generate myc(.p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]), .cin(cm[i]), .cout(ci[i*4+3: i*4]));
            pgm_generate mypgm(.p(p[i*4+3: i*4]), .g(g[i*4+3: i*4]), .pm(pm[i]), .gm(gm[i]));
        end
    endgenerate
    c_generate mycm(.p(pm), .g(gm), .cin(cm[0]), .cout(cm[4:1]]));
    assign result = p ^ ci;
endmodule
*/