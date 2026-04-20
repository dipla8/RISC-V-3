`ifndef TESTBENCH
`include "config.vh"
`else
`include "../includes/config.vh"
`endif
`timescale 1ns/1ns
module top();
	wire overflow; // NOT IMPLEMENTED
	wire msw_irq; // clint
	wire mtimer_irq; // clint
	wire mext_irq; // NOT IMPLEMENTED
	wire intr_en;
	wire write_pc;
	reg reset;
	reg cpu_clk;
	wire ren;
	wire wen;
	wire memReady1;
	wire memReady2;
	wire [31:0] PC1, PC2;
	wire [31:0] instruction_1, instruction_2;
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
		.PC_out_1(PC1),
		.PC_out_2(PC2),
		.instr_1(instruction_1),
		.instr_2(instruction_2),
		.ren(ren),
		.wen(wen),
		.data_addr(data_addr),
		.data_out(dataout_cpu),
		.data_in(datain_cpu),
		.byte_select(byte_selector),
		.software_interrupt(msw_irq),
		.timer_interrupt(mtimer_irq),
		.external_interrupt(mext_irq),
		.memReady(memReady1/* && memReady2*/)
	);
	memory_ctrl_i icache(
	.clk(cpu_clk),
	.reset(!reset),
	.address_1(PC1),
	.address_2(PC2),
	.wen(1'b0),
	.ren(1'b1),
	.byte_select_vector(byte_selector),
	.memReady(memReady1),
	.dataout_1(instruction_1),
	.dataout_2(instruction_2)
	);
	memory_ctrl_d dcache(
	.clk(cpu_clk),
	.reset(!reset),
	.address(data_addr),
	.datain(dataout_cpu),
	.wen(wen),
	.ren(ren),
	.byte_select_vector(byte_selector),
	.memReady(memReady2),
	.dataout(datain_cpu)
	);
	//clint clint1(
	//.clk(cpu_clk),
	//.reset(reset),
	//.addr(data_addr),
	//.wdata(dataout_cpu),
	//);*/
endmodule
