module cache(
input clk, reset, ren, wen,
input [31:0] address, datamemin, datawr,
output reg [31:0] dataout, datamemout,
output reg miss, memwr
);
// 8 sets
// 1 valid bit, 1 dirty bit, 29 bit tag, 32 bit data
reg [62:0] cmem [0:7][0:1]; // 2-WAY-SET-ASSOCIATIVE
reg [0:7] LRUbits;
integer i;
always @(negedge clk or posedge reset)begin
	// SET SIGNALS
	miss <= 0;
	memwr <= 0;
	if(reset)begin
		for(i = 0; i<8;i = i+ 1;)begin
			cmem[i][0][62] <= 0;
			// INVALIDATE ADDRESSES
		end
	end
	// HIT IF THE TAG MATCHES FOR EITHER BLOCK AND IF THEY ARE VALID
	if(ren && !wen)begin
		if (cmem[address[2:0]][0][50:31] == address[31:2] && cmem[address[2:0]][0][62])begin
			dataout <= cmem[address[2:0]][0][31:0];
			LRUbits[address[2:0]] <= 1;
		end
		else if (cmem[address[2:0]][1][50:31] == address[31:2] && cmem[address[2:0]][1][62])begin
			dataout <= cmem[address[2:0]][1][31:0];
			LRUbits[address[2:0]] <= 0;
		end
	// IF NOT ITS A MISS, GET THE DATA FROM THE MAIN MEM AND WRITE IT IN THE CACHE
		else begin
			miss <= 1;
			cmem[address[2:0]][LRUbits[address[2:0]]][62:61] <= 2'b10;
			cmem[address[2:0]][LRUbits[address[2:0]]][60:32] <= address[31:2];
			cmem[address[2:0]][LRUbits[address[2:0]]][31:0] <= datamemin;
			dataout <= datamemin;
			// PROBLHMA ME TO SYNCHRONIZATION, PWS THA GRAFTEI? NA APOFASISOUME!
		end
	end
	// WRITE ON THE APPROPRIATE VALID ADDRESS, MAKE THE BIT DIRTY
	if(wen && !ren)begin
		if (cmem[address[2:0]][0][50:31] == address[31:2] && cmem[address[2:0]][0][62])begin
			cmem[address[2:0]][0][31:0] <= datawr;
			cmem[address[2:0]][0][61] <= 1;
			LRUbits[address[2:0]] <= 1;
		end
		else if (cmem[address[2:0]][1][50:31] == address[31:2] && cmem[address[2:0]][1][62])begin
			cmem[address[2:0]][1][31:0] <= datawr;
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
			cmem[address[2:0]][LRUbits[address[2:0]]][31:0] <= datawr;
			cmem[address[2:0]][LRUbits[address[2:0]]][62:61] <= 2'b11;
		end
	end
	else begin
	// error
	end
end
endmodule
