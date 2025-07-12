module memory(
	input clk,
	input [31:0] addy,
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
	$readmemh("../includes/testbenchtext.hex", datamem);
	//`endif
end
always@(negedge clk)begin
	// READING
	if(ren && !wen)begin
		if(addy < 1024)begin
			dataout <= datamem[addy];
		end
		else dataout <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(addy < 1024)begin
			if(byte_selector[3])begin
				datamem[addy][31:24] = datain[31:24];
			end
			if(byte_selector[2])begin
				datamem[addy][23:16] = datain[23:16];
			end
			if(byte_selector[1])begin
				datamem[addy][15:8] = datain[15:8];
			end
			if(byte_selector[0])begin
				datamem[addy][7:0] = datain[7:0];
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
