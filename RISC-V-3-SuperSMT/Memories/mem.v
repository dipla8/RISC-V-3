module memory_i(
	input clk,
	input [31:0] address_1, address_2,
	input [31:0] datain_1, datain_2,
	input wen, ren,
	input [3:0] byte_selector,
	output reg [31:0] dataout_1, dataout_2,
	output reg memsig_1, memsig_2
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
	memsig_1<=1'b0;
	memsig_2<=1'b0;
	// READING
	if(ren && !wen)begin
		if(address_1 < 1024)begin
			dataout_1 <= datamem[address_1];
			memsig_1 <= 1'b1;
		end
		else dataout_1 <= 32'b0;
		if(address_2 < 1024)begin
			dataout_2 <= datamem[address_2];
			memsig_2 <= 1'b1;
		end
		else dataout_2 <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(address_1< 1024)begin
			if(byte_selector[3])begin
				datamem[address_1][31:24] = datain_1[31:24];
			end
			if(byte_selector[2])begin
				datamem[address_1][23:16] = datain_1[23:16];
			end
			if(byte_selector[1])begin
				datamem[address_1][15:8] = datain_1[15:8];
			end
			if(byte_selector[0])begin
				datamem[address_1][7:0] = datain_1[7:0];
			end
		end
		if(address_2< 1024)begin
			if(byte_selector[3])begin
				datamem[address_2][31:24] = datain_2[31:24];
			end
			if(byte_selector[2])begin
				datamem[address_2][23:16] = datain_2[23:16];
			end
			if(byte_selector[1])begin
				datamem[address_2][15:8] = datain_2[15:8];
			end
			if(byte_selector[0])begin
				datamem[address_2][7:0] = datain_2[7:0];
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
	output reg [31:0] dataout,
	output reg memsig
);
reg [31:0] datamem2[1023:0];
integer b;
initial begin
	for(b=0; b < 1024; b=b+1)begin
		datamem2[b] = 32'b0;
	end
	//`ifndef TESTBENCH
	//$readmemh(`TEXT_HEX, datamem);
	//`else
	$readmemh("../includes/datamem.hex", datamem2);
	//`endif
end
always@(posedge clk)begin
	memsig<=1'b0;
	// READING
	if(ren && !wen)begin
		if(address < 1024)begin
			dataout <= datamem2[address];
			$display("$$");
			$display("pulled data %h from %h", datamem2[address], address);
			$display("$$");
			memsig <= 1'b1;
		end
		else dataout <= 32'b0;
	end
	// WRITING
	else if(wen && !ren) begin
		if(address< 1024)begin
			if(byte_selector[3])begin
				datamem2[address][31:24] = datain[31:24];
			end
			if(byte_selector[2])begin
				datamem2[address][23:16] = datain[23:16];
			end
			if(byte_selector[1])begin
				datamem2[address][15:8] = datain[15:8];
			end
			if(byte_selector[0])begin
				datamem2[address][7:0] = datain[7:0];
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
