module sign_commands(
    input [1:0] op,
    input [31:0] number1,
    input [31:0] number2,
    output [31:0] out
);

wire s1,s2, f_sign;

assign s1 = number1[31];
assign s2 = number2[31];

assign f_sign = (op == 2'b00) ? s2 : 
                (op == 2'b01) ? ~s2:
                	 s1^s2;

assign out = {f_sign,number1[30:0]};

endmodule
