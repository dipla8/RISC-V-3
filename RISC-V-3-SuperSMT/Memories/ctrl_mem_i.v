module memory_ctrl_i(
	input clk,
	input reset,
	input [31:0] address_1, address_2,
	input wen,
	input ren,
	input [3:0] byte_select_vector,
	output reg memReady,
	output reg [31:0] dataout_1, dataout_2
);
	reg [31:0] old_address_1, old_address_2;
	wire [31:0] dataout_cache_1, dataout_cache_2;
	wire memwr_cache;
	wire [31:0] cache_dataout_1, cache_dataout_2;
	wire [31:0] dataout_mem_1, dataout_mem_2;
	wire memsig1;
	memory_i memory_inst(
	.clk(clk),
	.address_1(miss_cache_1?address_1>>2: 1025),
	.address_2(miss_cache_2?address_2>>2: 1025),
	.datain_1(dataout_cache_1),
	.datain_2(dataout_cache_2),
	.ren(miss_cache_1 || miss_cache_2),
	.wen(memwr_cache),
	.byte_selector(byte_select_vector),
	.dataout_1(dataout_mem_1),
	.dataout_2(dataout_mem_2),
	.memsig_1(memsig_1),
	.memsig_2(memsig_2)
);
	cache_i cache_i_inst(
	.clk(clk),
	.reset(reset),
	.wen(wen),
	.ren(ren && (!miss_cache_1 || !miss_cache_2 || memsig_1 || memsig_2)),
	.old_address_1(old_address_1>>2),
	.old_address_2(old_address_2>>2),
	.address_1(address_1>>2),
	.address_2(address_2>>2),
	.byte_selector(byte_select_vector),
	.datamemin_1(dataout_mem_1),
	.datamemin_2(dataout_mem_2),
	.dataout_1(cache_dataout_1),
	.dataout_2(cache_dataout_2),
	.datamemout_1(dataout_cache_1),
	.datamemout_2(dataout_cache_2),
	.miss_1(miss_cache_1),
	.miss_2(miss_cache_2),
	.memwr(memwr_cache)
);
	always @(*)begin
		dataout_1 <= cache_dataout_1;
		dataout_2 <= cache_dataout_2;
	end

	always @(*)begin
		memReady <= (!(miss_cache_1 && miss_cache_2 && !memsig_1 && !memsig_2) || reset);
	end
// FORWARD LOGIC (SO IT DOESN'T STALL)
	always @(posedge clk or posedge reset)begin
		if(reset)begin
			old_address_1 <= 32'b0;
			old_address_2 <= 32'b0;
		end
		if((memsig_1 || memsig_2) && !memwr_cache)begin
			/*if(byte_select_vector[3])
				dataout[31:24] <= dataout_mem[31:24];
			if(byte_select_vector[2])
				dataout[23:16] <= dataout_mem[23:16];
			if(byte_select_vector[1])
				dataout[15:8] <= dataout_mem[15:8];
			if(byte_select_vector[0])
				dataout[7:0] <= dataout_mem[7:0];
			*/
		     	if(memsig_1)begin
				dataout_1 <= dataout_mem_1;
			end
			if(memsig_2)begin
				dataout_2 <= dataout_mem_2;
			end
		end
		if(!memsig_1/* && miss_cache*/)begin
			old_address_1 <= address_1;
		end
		if(!memsig_2)begin
			old_address_2 <= address_2;
		end
		//if(!memsig1 && !miss_cache)begin
		//	old_address1 <= 32'bx;
		//end
	end
endmodule
