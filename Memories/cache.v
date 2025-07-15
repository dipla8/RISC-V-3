module cache(
input clk, reset, ren, wen,
input [3:0] byte_selector,
input [31:0] old_address,
input [31:0] address, datamemin, datawr,
output reg [31:0] dataout, datamemout,
output reg memwr,
output reg miss
);
// 8 sets
// 1 valid bit, 1 dirty bit, 29 bit tag, 32 bit data
reg [62:0] cmem [0:7][0:1]; // 2-WAY-SET-ASSOCIATIVE
reg [7:0] LRUbits;
integer i;
always @(negedge clk or posedge reset)begin
	// SET SIGNALS
	memwr <= 0;
	if(reset)begin
		//wnext <= 0;
		miss <= 0;
		LRUbits <= 8'b0;
		for(i = 0; i<8;i = i+ 1)begin
			cmem[i][0][62] <= 0;
			cmem[i][1][62] <= 0;
			// INVALIDATE ADDRESSES
		end
	end
	if(miss)begin
		miss <=0;
		cmem[old_address[2:0]][!LRUbits[old_address[2:0]]][31:0] <= datamemin;
		cmem[old_address[2:0]][!LRUbits[old_address[2:0]]][62:61] <= 2'b10;
		for (i = 0; i < 8; i = i + 1) begin
    $display("Set %0d - Way 0: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][0][62], cmem[i][0][61], cmem[i][0][60:32], cmem[i][0][31:0]);
    $display("Set %0d - Way 1: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][1][62], cmem[i][1][61], cmem[i][1][60:32], cmem[i][1][31:0]);
    		end
		//wnext <= 0;
	end
	// HIT IF THE TAG MATCHES FOR EITHER BLOCK AND IF THEY ARE VALID
	if(ren && !wen)begin
		if (cmem[address[2:0]][0][50:31] == address[31:2] && cmem[address[2:0]][0][62])begin
			miss <=0;
			dataout <= cmem[address[2:0]][0][31:0];
			LRUbits[address[2:0]] <= 1;
		end
		else if (cmem[address[2:0]][1][50:31] == address[31:2] && cmem[address[2:0]][1][62])begin
			miss <=0;
			dataout <= cmem[address[2:0]][1][31:0];
			LRUbits[address[2:0]] <= 0;
		end
	// IF NOT ITS A MISS, GET THE DATA FROM THE MAIN MEM AND WRITE IT IN THE CACHE
		else begin
			miss <= 1;
			//cmem[address[2:0]][LRUbits[address[2:0]]][62:61] <= 2'b10;
			cmem[address[2:0]][LRUbits[address[2:0]]][60:32] <= address[31:2];
			LRUbits[address[2:0]] = !LRUbits[address[2:0]];
			//wnext <= 1;
		end
	end
	// WRITE ON THE APPROPRIATE VALID ADDRESS, MAKE THE BIT DIRTY
	if(wen && !ren)begin
		if (cmem[address[2:0]][0][50:31] == address[31:2] && cmem[address[2:0]][0][62])begin
			miss <=0;
			if(byte_selector[3])
				cmem[address[2:0]][0][31:24] <= datawr[31:24];
			if(byte_selector[2])
				cmem[address[2:0]][0][23:16] <= datawr[23:16];
			if(byte_selector[1])
				cmem[address[2:0]][0][15:8] <= datawr[15:8];
			if(byte_selector[0])
				cmem[address[2:0]][0][7:0] <= datawr[7:0];
			cmem[address[2:0]][0][61] <= 1;
			LRUbits[address[2:0]] <= 1;
		end
		else if (cmem[address[2:0]][1][50:31] == address[31:2] && cmem[address[2:0]][1][62])begin
			miss <=0;
			if(byte_selector[3])
				cmem[address[2:0]][1][31:24] <= datawr[31:24];
			if(byte_selector[2])
				cmem[address[2:0]][1][23:16] <= datawr[23:16];
			if(byte_selector[1])
				cmem[address[2:0]][1][15:8] <= datawr[15:8];
			if(byte_selector[0])
				cmem[address[2:0]][1][7:0] <= datawr[7:0];
			cmem[address[2:0]][1][61] <= 1;
			LRUbits[address[2:0]] <= 0;
		end
	// IF NOT THEN, IN CASE THE DATA FOR EVICTION IS DIRTY TAKE IT BACK, OTHERWISE REPLACE IT WITH NO FURTHER THOUGHT
		else begin
			miss <= 1;
			if(cmem[address[2:0]][LRUbits[address[2:0]]][61])begin
				datamemout <= cmem[address[2:0]][LRUbits[address[2:0]]][61:0];
				memwr <=1;
			end
			cmem[address[2:0]][LRUbits[address[2:0]]][60:32] <= address[31:2];
			if(byte_selector[3])
				cmem[address[2:0]][LRUbits[address[2:0]]][31:24] <= datawr[31:24];
			if(byte_selector[2])
				cmem[address[2:0]][LRUbits[address[2:0]]][23:16] <= datawr[23:16];
			if(byte_selector[1])
				cmem[address[2:0]][LRUbits[address[2:0]]][15:8] <= datawr[15:8];
			if(byte_selector[0])
				cmem[address[2:0]][LRUbits[address[2:0]]][7:0] <= datawr[7:0];
			cmem[address[2:0]][LRUbits[address[2:0]]][62:61] <= 2'b11;
			LRUbits[address[2:0]] = !LRUbits[address[2:0]];
		end
	end
end
endmodule
