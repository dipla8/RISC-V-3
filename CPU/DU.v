module division_unit(
	input clk,
	input reset,
	input [4:0] ALUOp,
	input [31:0] inA,
	input [31:0] inB,
	input [5:0] cpu_divcy,
	output reg [5:0] du_divcy,
	output reg [31:0] rem,
	output trapdiv,
	output reg [31:0] quo
);
assign trapdiv = ((ALUOp == `DIV) && (ALUOp == `DIVU) && (inB)) ? 1'b0 : 1'b1;
reg [31:0] divisor;
reg [63:0] rediv;
reg sign;
integer i;
always@(posedge clk, posedge reset)begin
	if(reset)begin
		sign <= 0;
		du_divcy = 6'd32;
		rediv <= 64'b0;
		divisor <= 32'b0;
		rem <= 0;
		quo <= 0;
	end
	if(cpu_divcy == 0)begin
		du_divcy <= 6'd32;
	end
	if(ALUOp == `DIVU || ALUOp == `DIV)begin
	if(du_divcy == 6'd32)begin
		if(ALUOp == `DIV && inA[31] == 1)begin
			rediv[31:0] = ~(inA)+1;
			sign <= 1;
		end
		else begin
			rediv[31:0] = inA;
		end
		if(ALUOp == `DIV && inB[31] == 1)begin
			divisor = (~inB) + 1;
			sign <= !sign;
		end
		else begin
			divisor <= inB;
		end
		for(i=0; i<32; i= i+1)begin
			if(!(rediv[31-i]))begin
				du_divcy = du_divcy -1;
			end
			else begin
				i = 87; // break loop
			end
		end
		rediv[32:0] <= rediv[32:0] << (32-du_divcy+1); // yes 32 not 31
	end
	end
	if(((cpu_divcy != 6'd32) || (du_divcy != 6'd32)) && (cpu_divcy > 1))begin
		if(divisor > rediv[63:32])begin
			rediv <= rediv << 1;
		end
		else begin
			rediv[63:32] = rediv[63:32] - divisor;
			rediv = rediv << 1;
			rediv[0] = 1;
		end
	end
	if(cpu_divcy == 6'd1)begin
		if((sign == 1'b1)/* && (quo != 32'b0)*/)begin
			quo <= ~(rediv[31:0]) + 1;
			rem <= ~(rediv[61:32] >> 1) + 1;
		end
		else begin
			quo <= rediv[31:0];
			rem <= rediv[63:32] >> 1;
		end
	end
	if(cpu_divcy == 2 && du_divcy >= 6'd32)begin
		rem <= 0;
		quo <= 0;
	end
end
endmodule
