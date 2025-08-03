module memory_ctrl_i(
	input clk,
	input reset,
	input [31:0] address,
	input [31:0] datain,
	input wen,
	input ren,
	input [3:0] byte_select_vector,
	output reg memReady,
	output reg [31:0] dataout
);
	reg [31:0] old_address1;
	wire [31:0] dataout_cache;
	wire miss_cache;
	wire memwr_cache;
	wire [31:0] cache_dataout;
	wire [31:0] dataout_mem;
	wire memsig1;
	memory_i memory_inst(
	.clk(clk),
	.address(address>>2),
	.datain(dataout_cache),
	.ren(miss_cache),
	.wen(memwr_cache),
	.byte_selector(byte_select_vector),
	.dataout(dataout_mem),
	.memsig(memsig1)
);
	cache cache_inst(
	.clk(clk),
	.reset(reset),
	.wen(wen),
	.ren(ren && (!miss_cache || memsig1)),
	.old_address(old_address1>>2),
	.address(address>>2),
	.byte_selector(byte_select_vector),
	.datamemin(dataout_mem),
	.datawr(datain),
	.dataout(cache_dataout),
	.datamemout(dataout_cache),
	.miss(miss_cache),
	.memwr(memwr_cache)
);
	always @(cache_dataout)begin
		dataout <= cache_dataout;
	end
	always @(miss_cache or memsig1 or reset)begin
		memReady <= (!(miss_cache && !memsig1) || reset);
	end
// FORWARD LOGIC (SO IT DOESN'T STALL)
	always @(posedge clk or posedge reset)begin
		if(reset)begin
			old_address1 <= 32'b0;
		end
		if(miss_cache && !memwr_cache)begin
			if(byte_select_vector[3])
				dataout[31:24] <= dataout_mem[31:24];
			if(byte_select_vector[2])
				dataout[23:16] <= dataout_mem[23:16];
			if(byte_select_vector[1])
				dataout[15:8] <= dataout_mem[15:8];
			if(byte_select_vector[0])
				dataout[7:0] <= dataout_mem[7:0];
		end
		if(!memsig1/* && miss_cache*/)begin
			old_address1 <= address;
		end
		//if(!memsig1 && !miss_cache)begin
		//	old_address1 <= 32'bx;
		//end
	end
endmodule
