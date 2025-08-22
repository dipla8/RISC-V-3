module fpu(
	input  op, // 1 bit, to be extended
	input [31:0] inA, inB,
	output reg [31:0] out
);
integer i, shiftAmount;
reg [27:0] mant;
reg [27:0] res;
always@(inA or inB)begin
	if(op == `FADD)begin
		if(inA[30:23] >= inB[30:23])begin
			mant[27:0] = {2'b01, inB[22:0], 3'b000};
			mant = mant >> (inA[30:23] - inB[30:23]);
			res = (((-1) *inA[31])*{2'b01, inA[22:0], 3'b0}) + (((-1) *inB[31]) * mant[25:0]);
			if(res[26])begin
				out[31] = inA[31]; // is true for all inA>inB exponent
				out[30:23] = inA[30:23]+1'b1;
				// case for rounding
				out[22:0] = res[25:3];
			end
			else begin
				shiftAmount = 0;
				for(i=0 ; (i<26 && !res[26]);i++)begin
					shiftAmount = shiftAmount+1;
					res = res << 1;
				end
				out[31] = inA[31];
				out[30:23] = inA[30:23] - shiftAmount;
				// case for rounding
				out[22:0] = res[25:3];
			end
		end
		else begin
			mant[27:0] = {2'b01, inA[22:0], 3'b000};
			mant = mant >> (inB[30:23] - inA[30:23]);
			res = (((-1) *inA[31]) * mant[25:0]) + (((-1) *inB[31])*{2'b01, inB[22:0], 3'b0});
			if(res[26])begin
				out[31] = inB[31]; // is true for all inA>inB exponent
				out[30:23] = inB[30:23]+1'b1;
				// case for rounding
				out[22:0] = res[25:3];
			end
			else begin
				shiftAmount = 0;
				for(i=0 ; (i<26 && !res[26]);i++)begin
					shiftAmount = shiftAmount+1;
					res = res << 1;
				end
				out[31] = inB[31];
				out[30:23] = inB[30:23] - shiftAmount;
				// case for rounding
				out[22:0] = res[25:3];
			end
		end
	end
end
endmodule
