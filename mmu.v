module memory_management_unit(
	input clk,
	input reset,
	input [31:0] addy,
	input [31:0] datain,
	input wen,
	input ren,
	input [3:0] byte_select_vector
	output reg nostall,
	output reg dataout
);
	reg old_address;
	wire dataout_cache;
	wire miss_cache;
	wire dataout_mem
	memory memory_inst(
	.clk(clk),
	.reset(reset),
	.addy(addy),
	.datain(dataout_cache),
	.ren(miss_cache),
	.wen(memwr)
	.byte_selector(byte_select_vector),
	.dataout(dataout_mem);
);
	cache cache_inst(
	.clk(clk),
	.wen(wen),
	.ren(ren),
	.address(addy),
	.datamemin(dataout_mem),
	.datawr(datain),
	.dataout(dataout),
	.datamemout(dataout_cache)
);
// FORWARD LOGIC (SO IT DOESN'T STALL)
	always @(negedge clk or posedge reset)begin
		if(reset)begin
			old_address <= 0;
		end
		if(ren && !wen && (addy == old_address))begin
			dataout <= dataout_mem;
		end
		old_address <= addy;
	end
