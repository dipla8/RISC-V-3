`include "../includes/config.vh"
module floating_convert(input [4:0] FPUOp, input [31:0] in_num, output reg [31:0] out, output reg overflow);
`include "../CPU/function_ace.vh"
wire exp;
wire sign;
wire in_num2;
wire [4:0] first_ace;
assign exp = in_num[30:23] -127;
assign in_num2 = in_num[31] ? !(in_num) + 1 : in_num;
assign sign = in_num[31];
assign first_ace = first_ace_func(in_num2);
always@(*)begin
case(FPUOp)
	`FCVTWS: {overflow,out} <= (!(exp>=0? {10'b0, in_num[22:0]} << exp : {10'b0, in_num[22:0]} >> (-exp))+1) ^ 33'b100000000000000000000000000000000;
	`FCVTWUS: {overflow,out} <= (exp>=0? {10'b0, in_num[22:0]} << exp : {10'b0, in_num[22:0]} >> (-exp));
	`FMVXW: {overflow,out} <= {1'b0,in_num};
	`FCLASS: {overflow,out} <= {23'b0,
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'hFF) && (in_num[22:0] == 23'b10000000000000000000000)),
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'hFF) && (in_num[22:0] == 23'b00000000000000000000001)),
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'hFF) && (in_num[22:0] == 23'b00000000000000000000000)),
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'h80) && (in_num[22:0] == 23'b01000000000000000000000)),
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'h00) && (in_num[22:0] == 23'b00000000000000000000001)),
			((in_num[31] == 1'b0) && (in_num[30:23] == 8'h00) && (in_num[22:0] == 23'b00000000000000000000000)),
			((in_num[31] == 1'b1) && (in_num[30:23] == 8'h00) && (in_num[22:0] == 23'b00000000000000000000000)),
			((in_num[31] == 1'b1) && (in_num[30:23] == 8'h00) && (in_num[22:0] == 23'b00000000000000000000001)),
			((in_num[31] == 1'b1) && (in_num[30:23] == 8'h80) && (in_num[22:0] == 23'b01000000000000000000000)),
			((in_num[31] == 1'b1) && (in_num[30:23] == 8'hFF) && (in_num[22:0] == 23'b00000000000000000000000))};
	`FCVTSW,
	`FCVTSWU:begin
		if(FPUOp == `FCVTSW)begin
			{overflow, out} <= {first_ace >= 5'd23, sign, first_ace+1'b1 , in_num[first_ace -:24]};
		end
		else begin
			{overflow, out} <= {first_ace >= 5'd23, 1'b0, first_ace+1'b1 , in_num[first_ace -:24]};
		end
		end
	`FMVWX: {overflow,out} <= {1'b0, in_num};
endcase
end
endmodule
