module memory_i(
	input clk,
	input [31:0] address,
	input [31:0] datain,
	input wen, ren,
	input [3:0] byte_selector,
	output reg [31:0] dataout,
	output reg memsig
);
reg [31:0] datamem[1023:0];
integer i;
initial begin
	for(i=0; i < 1024; i=i+1)begin
		datamem[i] = 32'b0;
	end
	//`ifndef TESTBENCH
	//$readmemh(`TEXT_HEX, datamem);
	//`else
	$readmemh("../includes/testbenchtext.hex", datamem);
	//`endif
end
always@(posedge clk)begin
	memsig<=1'b0;
	// READING
	if(ren && !wen)begin
		if(address < 1024)begin
			dataout <= datamem[address];
			memsig <= 1'b1;
		end
		else dataout <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(address< 1024)begin
			if(byte_selector[3])begin
				datamem[address][31:24] = datain[31:24];
			end
			if(byte_selector[2])begin
				datamem[address][23:16] = datain[23:16];
			end
			if(byte_selector[1])begin
				datamem[address][15:8] = datain[15:8];
			end
			if(byte_selector[0])begin
				datamem[address][7:0] = datain[7:0];
			end
		end
		else begin 
		//error
		end
	end
	else begin
	//error
	end
end
endmodule
module memory_d(
	input clk,
	input [31:0] address,
	input [31:0] datain,
	input wen, ren,
	input [3:0] byte_selector,
	output reg [31:0] dataout
);
reg [31:0] datamem[1023:0];
integer i;
initial begin
	for(i=0; i < 1024; i=i+1)begin
		datamem[i] = 32'b0;
	end
	//`ifndef TESTBENCH
	//$readmemh(`TEXT_HEX, datamem);
	//`else
	$readmemh("../includes/datamem.hex", datamem);
	//`endif
end
always@(negedge clk)begin
	// READING
	if(ren && !wen)begin
		if(address < 1024)begin
			dataout <= datamem[addy];
		end
		else dataout <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(address < 1024)begin
			if(byte_selector[3])begin
				datamem[addy][31:24] = datain[31:24];
			end
			if(byte_selector[2])begin
				datamem[address][23:16] = datain[23:16];
			end
			if(byte_selector[1])begin
				datamem[address][15:8] = datain[15:8];
			end
			if(byte_selector[0])begin
				datamem[address][7:0] = datain[7:0];
			end
		end
		else begin 
		//error
		end
	end
	else begin
	//error
	end
end
endmodule
