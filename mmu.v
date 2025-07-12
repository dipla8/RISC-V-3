module memory_management_unit(
	input clk,
	input reset,
	input [31:0] addy,
	input [31:0] datain,
	input wen,
	input ren,
	input [3:0] byte_select_vector,
	output reg nostall,
	output reg [31:0] dataout
);
	reg [31:0] old_address;
	wire dataout_cache;
	wire miss_cache;
	wire memwr_cache;
	wire cache_dataout;
	wire [31:0] dataout_mem;
	memory memory_inst(
	.clk(clk),
	.reset(reset),
	.addy(addy),
	.datain(dataout_cache),
	.ren(miss_cache),
	.wen(memwr_cache),
	.byte_selector(byte_select_vector),
	.dataout(dataout_mem)
);
	cache cache_inst(
	.clk(clk),
	.wen(wen),
	.ren(ren),
	.address(addy),
	.byte_selector(byte_select_vector),
	.datamemin(dataout_mem),
	.datawr(datain),
	.dataout(cache_dataout),
	.datamemout(dataout_cache),
	.miss(miss_cache),
	.memwr(memwr_cache)
);
	always @(miss_cache or memwr_cache)
		nostall <= !(miss_cache && !(memwr_cache));
	always @(cache_dataout)
		dataout <= cache_dataout;
// FORWARD LOGIC (SO IT DOESN'T STALL)
	always @(negedge clk or posedge reset)begin
		if(reset)begin
			old_address <= 32'b0;
		end
		if(ren && !wen && (addy == old_address))begin
			dataout <= dataout_mem;
		end
		old_address <= addy;
	end
endmodule
