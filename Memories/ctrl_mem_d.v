module memory_management_unit_d(
	input clk,
	input reset,
	input [31:0] addy,
	input [31:0] datain,
	input wen,
	input ren,
	input [3:0] byte_select_vector,
	output wire nostall,
	output reg [31:0] dataout
);

	reg [31:0] old_address1;
	wire [31:0] dataout_cache;
	wire miss_cache;
	wire memwr_cache;
	wire [31:0] cache_dataout;
	wire [31:0] dataout_mem;

	memory_d memory_inst(
		.clk(clk),
		.addy(addy),
		.datain(dataout_cache),
		.ren(miss_cache),
		.wen(memwr_cache),
		.byte_selector(byte_select_vector),
		.dataout(dataout_mem)
	);

	cache cache_inst(
		.clk(clk),
		.reset(reset),
		.wen(wen),
		.ren(ren),
		.old_address(old_address1),
		.address(addy),
		.byte_selector(byte_select_vector),
		.datamemin(dataout_mem),
		.datawr(datain),
		.dataout(cache_dataout),
		.datamemout(dataout_cache),
		.miss(miss_cache),
		.memwr(memwr_cache)
	);
	
	assign nostall = !(miss_cache && !(memwr_cache));
	always @(cache_dataout)begin
		dataout = cache_dataout;
	end
// FORWARD LOGIC (SO IT DOESN'T STALL)
	always @(negedge clk or posedge reset)begin
		if(reset)begin
			old_address1 <= 32'b0;
		end
		if(ren && !wen && (addy == old_address1))begin
			dataout <= dataout_mem;
		end
		old_address1 <= addy;
	end
endmodule
