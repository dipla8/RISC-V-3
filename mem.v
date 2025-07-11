module memory(
	input clk,
	input reset,
	input [31:0] addy,
	input [31:0] datain,
	input wen, ren,
	input [3:0] byte_selector
	output reg [31:0] dataout
);
reg [1023:0] datamem[31:0];
integer i;
always@(negedge clk or posedge reset)begin
	// RESET
	if(reset)begin
		for(i=0; i<1024; i = i+1)begin
			datamem[32:0][i] = 32'b0;
		end
		`ifndef TESTBENCH
		$readmemh(`TEXT_HEX, datamem);
		`else
		$readmemh("../includes/testbenchtext.hex", datamem);
		`endif
	end
	// READING
	if(ren && !wen)begin
		if(addy < 1024)begin
			dataout <= datamem[31:0][addy];
		end
		else dataout <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(addy < 1024)begin
			if(byte_selector[3])
				datamem[31:24][addy] = datain[31:24];
			if(byte_selector[2])
				datamem[23:16][addy] = datain[23:16];
			if(byte_selector[1])
				datamem[15:8][addy] = datain[15:8];
			if(byte_selector[0])
				datamem[7:0][addy] = datain[7:0];
		end
		else //error
	end
	else
	//error
	end
end
