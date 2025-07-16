`ifndef TESTBENCH
`include "config.vh"
`else
`include "../includes/config.vh"
`endif
`timescale 1ns/1ns
module top(
	
);
	wire overflow; // NOT IMPLEMENTED
	wire msw_irq; // clint
	wire mtimer_irq; // clint
	wire mext_irq; // NOT IMPLEMENTED
	wire intr_en;
	wire write_pc;
	wire memReady1;
	reg reset;
	reg cpu_clk;
	wire ren;
	wire wen;
	wire [31:0] PC;
	wire [31:0] instruction;
	wire [31:0] data_addr;
	wire [31:0] dataout_cpu;
	wire [31:0] datain_cpu;
	wire [3:0] byte_selector;
	always #1 cpu_clk <= !cpu_clk;
	initial begin
		cpu_clk = 0;
		reset = 0;
		#2 reset = 1;
	end
	cpu cpu1(
		.clock(cpu_clk),
		.reset(reset),
		.overflow(overflow),
		.PC_out(PC),
		.instr_in(instruction),
		.ren(ren),
		.wen(wen),
		.data_addr(data_addr),
		.data_out(dataout_cpu),
		.data_in(datain_cpu),
		.byte_select(byte_selector),
		.software_interrupt(msw_irq),
		.timer_interrupt(mtimer_irq),
		.external_interrupt(mext_irq),
		.instr_en(instr_en),
		.write_pc_out(write_pc),
		.memReady(memReady1)
	);
	memory_management_unit_i icache(
	.clk(cpu_clk),
	.reset(!reset),
	.address(PC),
	.datain(32'b0),
	.wen(1'b0),
	.ren(instr_en),
	.byte_select_vector(byte_selector),
	.memReady(memReady1),
	.dataout(instruction)
	);
	/*memory_management_unit_d dcache(
	.clk(cpu_clk),
	.reset(!reset),
	.addy(data_addr),
	.datain(dataout_cpu),
	.wen(wen),
	.ren(ren),
	.byte_select_vector(byte_selector),
	.memReady(memReady),
	.dataout(datain_cpu)
	);
	//clint clint1(
	//.clk(cpu_clk),
	//.reset(reset),
	//.addr(data_addr),
	//.wdata(dataout_cpu),
	//);*/
endmodule
