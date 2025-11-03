module fsqrt(input [31:0] in_num, output [31:0] out);
reg [31:0] magic = 32'h5F3759DF;
assign out = magic - (in_num>>1);
endmodule
