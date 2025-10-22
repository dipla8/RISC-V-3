`timescale 1ns/1ns
module soctb;
reg reset = 1;
reg [3:0] display [3:0];
reg [3:0] message [15:0];
reg button = 0;
reg clk = 1;
wire [3:0] a,b,c,d;
wire [7:0] LED;
wire [3:0] an;
FourDigitLEDdriver dut(display[0], display[1], display[2], display[3], clk, reset, button, a, b, c ,d, LED, an);
initial begin
	#10 reset <= 0;
end
always #1 clk <= !clk;
initial begin
	message[0] <= 4'b0000;
	message[1] <= 4'b0001;
	message[2] <= 4'b0010;
	message[3] <= 4'b0011;
	message[4] <= 4'b0100;
	message[5] <= 4'b0101;
	message[6] <= 4'b0110;
	message[7] <= 4'b0111;
	message[8] <= 4'b1000;
	message[9] <= 4'b1001;
	message[10] <= 4'b1010;
	message[11] <= 4'b1011;
	message[12] <= 4'b1100;
	message[13] <= 4'b1101;
	message[14] <= 4'b1110;
	message[15] <= 4'b1111;
	
	#5 button <= 1;
	#5 button <= 0;

	#5 button <= 1;
	#5 button <= 0;

	#5 button <= 1;
	#5 button <= 0;

	#5 button <= 1;
	#5 button <= 0;

	#5 button <= 1;
	#5 button <= 0;

	#5 button <= 1;
	#5 button <= 0;

	#20000 $finish;
end
always @(a, b, c, d)begin
	display[0] <= message[a];
	display[1] <= message[b];
	display[2] <= message[c];
	display[3] <= message[d];
end
endmodule
