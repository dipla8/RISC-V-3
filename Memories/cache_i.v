module cache_i(
input clk, reset, ren, wen,
input [3:0] byte_selector,
input [31:0] old_address_1, old_address_2,
input [31:0] address_1, address_2, datamemin_1, datamemin_2, datawr_1, datawr_2,
output reg [31:0] dataout_1, dataout_2, datamemout_1, datamemout_2,
output reg memwr,
output reg miss_1, miss_2
);
// 8 sets
// 1 valid bit, 1 dirty bit, 29 bit tag, 32 bit data
reg [62:0] cmem [0:7][0:1]; // 2-WAY-SET-ASSOCIATIVE
reg [7:0] LRUbits;
integer i;
always @(posedge clk or posedge reset)begin
	// SET SIGNALS
	memwr <= 0;
	if(reset)begin
		miss_1 <= 0;
		miss_2 <= 0;
		LRUbits <= 8'b0;
		for(i = 0; i<8;i = i+ 1)begin
			cmem[i][0][62] <= 0;
			cmem[i][1][62] <= 0;
			// INVALIDATE ADDRESSES
		end
	end
	if(miss_1 && !(miss_2 && address_1[2:0] == address_2[2:0]))begin
		miss_1 <=0;
		cmem[old_address_1[2:0]][!LRUbits[old_address_1[2:0]]][60:32] <= old_address_1[31:3];
		cmem[old_address_1[2:0]][!LRUbits[old_address_1[2:0]]][31:0] <= datamemin_1;
		if(^datamemin_1 === 1'bx)begin
			cmem[old_address_1[2:0]][!LRUbits[old_address_1[2:0]]][62:61] <= 2'b00;
		end
		else begin
			cmem[old_address_1[2:0]][!LRUbits[old_address_1[2:0]]][62:61] <= 2'b10;
		end
		LRUbits[address_1[2:0]] = !LRUbits[address_2[2:0]];
		for (i = 0; i < 8; i = i + 1) begin
    $display("ADD1: Set %0d - Way 0: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][0][62], cmem[i][0][61], cmem[i][0][60:32], cmem[i][0][31:0]);
    $display("ADD1: Set %0d - Way 1: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][1][62], cmem[i][1][61], cmem[i][1][60:32], cmem[i][1][31:0]);
    		end
    		$display("ADD1 added %h...", old_address_1<<2);
	end
	if(miss_2 && !(miss_1 && address_1[2:0] == address_2[2:0]))begin
		miss_2 <=0;
		cmem[old_address_2[2:0]][!LRUbits[old_address_2[2:0]]][60:32] <= old_address_2[31:3];
		cmem[old_address_2[2:0]][!LRUbits[old_address_2[2:0]]][31:0] <= datamemin_2;
		if(^datamemin_2 === 1'bx)begin
			cmem[old_address_2[2:0]][!LRUbits[old_address_2[2:0]]][62:61] <= 2'b00;
		end
		else begin
			cmem[old_address_2[2:0]][!LRUbits[old_address_2[2:0]]][62:61] <= 2'b10;
		end
		LRUbits[address_2[2:0]] = !LRUbits[address_2[2:0]];	
		for (i = 0; i < 8; i = i + 1) begin
    $display("ADD2: Set %0d - Way 0: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][0][62], cmem[i][0][61], cmem[i][0][60:32], cmem[i][0][31:0]);
    $display("ADD2: Set %0d - Way 1: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][1][62], cmem[i][1][61], cmem[i][1][60:32], cmem[i][1][31:0]);
    		end
    		$display("ADD2 added %h...", old_address_2<<2);
	end
	if(miss_1 && miss_2 && (address_1[2:0] == address_2[2:0]))begin
		miss_1 <= 0;
		miss_2 <= 0;
		cmem[old_address_1[2:0]][0][60:32] <= old_address_1[31:3];
		cmem[old_address_1[2:0]][0][31:0] <= datamemin_1;
		cmem[old_address_1[2:0]][0][60:32] <= old_address_1[31:3];
		cmem[old_address_1[2:0]][0][31:0] <= datamemin_1;
		if(^datamemin_1 === 1'bx)begin
			cmem[old_address_1[2:0]][0][62:61] <= 2'b00;
		end
		else begin
			cmem[old_address_1[2:0]][0][62:61] <= 2'b10;
		end
		if(^datamemin_2 === 1'bx)begin
			cmem[old_address_2[2:0]][1][62:61] <= 2'b00;
		end
		else begin
			cmem[old_address_2[2:0]][1][62:61] <= 2'b10;
		end
		LRUbits[address_1[2:0]] = 0;	
		for (i = 0; i < 8; i = i + 1) begin
    $display("Set %0d - Way 0: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][0][62], cmem[i][0][61], cmem[i][0][60:32], cmem[i][0][31:0]);
    $display("Set %0d - Way 1: V=%b D=%b TAG=%h DATA=%h", i, cmem[i][1][62], cmem[i][1][61], cmem[i][1][60:32], cmem[i][1][31:0]);
    		end
    		$display("added %h, %h...", old_address_1<<2, old_address_2<<2);
	end

	// HIT IF THE TAG MATCHES FOR EITHER BLOCK AND IF THEY ARE VALID
	if(ren && !wen)begin
		if ((cmem[address_1[2:0]][0][60:32] == address_1[31:3]) && (cmem[address_1[2:0]][0][62]))begin
			miss_1 <= 0;
			dataout_1 <= cmem[address_1[2:0]][0][31:0];
			LRUbits[address_1[2:0]] <= 1;
		end
		else if ((cmem[address_1[2:0]][1][60:32] == address_1[31:3]) && (cmem[address_1[2:0]][1][62]))begin
			miss_1 <=0;
			dataout_1 <= cmem[address_1[2:0]][1][31:0];
			LRUbits[address_1[2:0]] <= 0;
		end
	// IF NOT ITS A MISS, GET THE DATA FROM THE MAIN MEM AND WRITE IT IN THE CACHE
		else begin
			miss_2 <= 1;
			if(cmem[address_2[2:0]][LRUbits[address_2[2:0]]][61])begin
				datamemout_2 <= cmem[address_2[2:0]][LRUbits[address_2[2:0]]][61:0];
				memwr <=1;
			end
		end
		if ((cmem[address_2[2:0]][0][60:32] == address_2[31:3]) && (cmem[address_2[2:0]][0][62]))begin
			miss_2 <=0;
			dataout_2 <= cmem[address_2[2:0]][0][31:0];
			LRUbits[address_2[2:0]] <= 1;
		end
		else if ((cmem[address_2[2:0]][1][60:32] == address_2[31:3]) && (cmem[address_2[2:0]][1][62]))begin
			miss_2 <=0;
			dataout_2 <= cmem[address_2[2:0]][1][31:0];
			LRUbits[address_2[2:0]] <= 0;
		end
		else begin
			miss_1 <= 1;
			if(cmem[address_2[2:0]][LRUbits[address_2[2:0]]][61])begin
				datamemout_2 <= cmem[address_2[2:0]][LRUbits[address_2[2:0]]][61:0];
				memwr <=1;
			end
		end
	end
end
endmodule
