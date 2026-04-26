`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif


/*****************************************************************************************/
/* Implementation of the 5-stage MIPS pipeline that supports the following instructions: */
/*  R-format: add, sub, and, or, xor, slt                                                */
/*  addi, lw, sw, beq, j                                                                 */
/*****************************************************************************************/
module cpu(	input	clock,
			input 	reset,
			input  	[31:0] instr_in0,
			input	[31:0] instr_in1,
			input 	[31:0] data_in,
			input 	software_interrupt,
			input 	timer_interrupt,
			input 	external_interrupt,
			input 	memReady,
			output 	overflow,
			output 	[31:0] PC_out,
			output 	[31:0] data_addr,
			output 	ren,
			output 	wen,
			output 	instr_en,
			output 	[31:0] data_out,
			output 	[3:0]  byte_select,
			output 	write_pc_out
			);
// // Data memory 1KB
// Dmem cpu_DMem(
// 	.clock(clock), 
// 	.reset(reset),
// 	.ren(EXMEM_MemRead), 
// 	.wen(EXMEM_MemWrite), 
// 	.byte_select_vector(byte_select_vector), 
// 	.addr(EXMEM_ALUOut[`DATA_BITS-1:2]), 
// 	.din(MemWriteData), 
// 	.dout(DMemOut)
// );
reg		[31:0]	IFID_instr0;
reg		[31:0]	IFID_instr1;
reg 	[31:0]  PC_IF2;
reg		[31:0]	PC, PC_OLD, IFID_PC, IDEX_PC, EXMEM_PC, MEMWB_PC;
wire	[31:0]	PCplus4, JumpAddress0, JumpAddress1;
reg 	[31:0] 	PC_new;
reg		[31:0]	IF2_instr0;
reg     [31:0]  IF2_instr1;
reg		[31:0]	IDEX_instr;
reg		[31:0]	EXMEM_instr;
reg		[31:0]	MEMWB_instr;
reg     [31:0]  delayed_instr0;
reg		[31:0]	delayed_instr1;
wire			inA_is_PC, branch_taken;
wire	[31:0]	BranchInA;
reg		[31:0]	IDEX_signExtend0, IDEX_signExtend1;
wire	[31:0]	signExtend0, signExtend1;
wire	[31:0]	rdA, rdB;
wire	[31:0] 	FPUOut;
reg		[31:0]	IDEX_rdA, IDEX_rdB;
reg		[2:0]	IDEX_funct3_0, IDEX_funct3_1;
reg		[6:0]	IDEX_funct7;
reg		[4:0]	IDEX_instr_rs2, IDEX_instr_rs1, IDEX_instr_rd;
reg				IDEX_RegDst, IDEX_ALUSrc, IDEX_inA_is_PC, IDEX_JumpJALR;
reg 	[1:0]	IDEX_Jump;
reg 	[2:0] 	IDEX_reg_type_0, IDEX_reg_type_1;
reg		[3:0]	IDEX_EXcntrl;
reg				IDEX_MemRead, IDEX_MemWrite;
reg				IDEX_MemToReg, IDEX_RegWrite;
reg 	[2:0]	EXMEM_funct3_0, EXMEM_funct3_1, MEMWB_funct3_0, MEMWB_funct3_1;
reg 	[4:0]	EXMEM_RegWriteAddr;
reg 	[31:0]	EXMEM_ALUOut;
reg 	[31:0]	EXMEM_BranchALUOut;
reg 	[2:0] 	EXMEM_reg_type_0, EXMEM_reg_type_1;
reg				EXMEM_Zero, EXMEM_JumpJALR;
wire	[3:0]	byte_select_vector;
reg		[31:0]	EXMEM_MemWriteData;
wire	[31:0]	MemWriteData;
reg				EXMEM_MemRead, EXMEM_MemWrite, EXMEM_RegWrite, EXMEM_MemToReg;
reg		[31:0]	MEMWB_DMemOut;
reg		[4:0]	MEMWB_RegWriteAddr;
reg		[31:0]	MEMWB_ALUOut;
reg				MEMWB_MemToReg, MEMWB_RegWrite;
reg 	[2:0] 	MEMWB_reg_type_0, MEMWB_reg_type_1;
// alu signals
reg 	[31:0] 	ALUInA, ALUInB;
wire 	[31:0] 	bypassOutA, bypassOutB;
wire	[31:0]	ALUOut, BranchALUOut, DMemOut, MemOut;
wire	[31:0]	divrem, divres;
reg     [31:0]  wRegData;
reg     [31:0]  WB_csr_data;
wire			Zero, RegDst, MemRead, MemWrite, MemToReg, ALUSrc, PCSrc, RegWrite, JumpJALR;
wire 	[1:0]	Jump;
wire 	[2:0] 	reg_type_0, reg_type_1; // used to determin if we are using the x0-x31 registers, csr registers or f1-f32 registers. 0->x register 1->csr register 2->f register 
wire			Branch;
reg				IDEX_Branch, EXMEM_Branch;
wire			bubble_ifid, bubble_idex, bubble_exmem, bubble_memwb;   // create a NOP in respective stages
wire			write_ifid, write_idex, write_exmem, write_memwb, write_pc;  // enable/disable pipeline registers
wire	[6:0]	opcode0, opcode1;
wire	[3:0]	funct3_0, funct3_1, EXcntrl; 
// csr registers

// csr file output
wire 	[31:0] 	csr_data;
reg 	[31:0] 	EXMEM_csr_data;
reg 	[31:0] 	MEMWB_csr_data;
// csr write address
wire 	[11:0]	csr_addr0, csr_addr1;
reg 	[11:0]	IDEX_csr_addr;
reg 	[11:0]	EXMEM_csr_addr;
reg 	[11:0]	MEMWB_csr_addr;

reg 			csr_write_allowed_0, csr_write_allowed_1;
reg 			IDEX_csr_write_allowed_0, IDEX_csr_write_allowed_1;
reg 			EXMEM_csr_write_allowed_0, EXMEM_csr_write_allowed_1;
reg 			MEMWB_csr_write_allowed_0, MEMWB_csr_write_allowed_1;

wire       		csr_immidiate;
reg      		IDEX_csr_immidiate;
reg      		EXMEM_csr_immidiate;
reg      		MEMWB_csr_immidiate;


reg		[5:0]	local_divcy;
wire	[5:0]	divcy;
wire	[6:0]	funct7_0, funct7_1;
wire	[4:0]	instr0_rs1, instr0_rs2, instr0_rd, RegWriteAddr;
wire	[4:0]	instr1_rs1, instr1_rs2, instr1_rd;
wire	[4:0]	ALUOp;
wire 	[4:0]	FPUOp; // one bit long thus far, improvements will be added
wire	[1:0]	bypassA, bypassB;
wire	[31:0]	imm_i_0, imm_s_0, imm_b_0, imm_u_0, imm_j_0, imm_z_0;
wire	[31:0]	imm_i_1, imm_s_1, imm_b_1, imm_u_1, imm_j_1, imm_z_1;
reg				keepDelayInstr=0;

// trap handler signals
wire 			int_taken;
wire	[31:0]	trap_vector;
wire			syscall, trap_waiting;
wire			trap_in_ID;
// reg trap_in_EX=0;
// reg trap_in_MEM=0;

wire	[31:0]	instr;
wire	[31:0]	instr1;

assign PC_out = PC;
assign instr0 = instr_in0;
assign instr1 = instr_in1;
assign write_pc_out = write_pc;
assign data_addr = (ren==1'b1)?ALUOut:EXMEM_ALUOut;
assign ren = IDEX_MemRead&(~branch_taken);
assign wen = EXMEM_MemWrite;
assign data_out = MemWriteData;
assign DMemOut = data_in;
assign byte_select = byte_select_vector;
/********************** Instruction Fetch Unit (IF1)  **********************/
always @(posedge clock or negedge reset)
begin 
	if (reset == 1'b0)
	begin
		PC <= `INITIAL_PC; 
	end
	else if (write_pc == 1'b1)
	begin
		PC <= PC_new;
	end
	else
	begin
		//PC <= PC_IF2;
	end
end

reg write_pc_delayed;
reg bubble_ifid_delayed;

/***************************** Instruction Fetch Unit (IF2)  *******************/
// This stage is used to control the instruction output of the IF stages

// fix 1 for IF2 stages
// Keep delay instruction is used when we have a stall
// When we have a stall the PC continues for one cycle
// but the instruction is not passed to the next stage, hence we keep it
// on delayed_instr until the stall is resolved

// fix 2 for IF2 stages
// since we now have two stages in the IF,
// we need to bubble the IFID register for two cycles when jumping/branching
always @(posedge clock or negedge reset)
begin
	if(reset == 1'b0)begin
		PC_IF2 <= 32'b0;
		write_pc_delayed <= 1'b0;
		bubble_ifid_delayed <= 1'b0;
	end
	else begin
		write_pc_delayed <= write_pc;
		if(write_ifid == 1'b1)begin
			if(bubble_ifid == 1'b1)begin
				PC_IF2 <= 32'hffffffff;
			end
			else begin
				PC_IF2 <= PC;
			end

			bubble_ifid_delayed <= bubble_ifid;
			delayed_instr0 <= 0;
			delayed_instr1 <= 0;
			keepDelayInstr <= 0;
		end
		else begin
			if(bubble_ifid == 1'b1||bubble_ifid_delayed == 1'b1)begin
				PC_IF2 <= 32'hffffffff;
			end

			if(keepDelayInstr == 1'b0) begin
				keepDelayInstr <= 1'b1;
				delayed_instr0 <= (PCSrc) ? 32'hffffffff : instr0;
				delayed_instr1 <= (PCSrc) ? 32'hffffffff : instr1;
			end
		end
	end
end


// if a cache is to be put here, this needs to be modified.
// also make sure that the cache only handles specific addresses
always@(*)
begin
	if(delayed_instr0 == 0 && delayed_instr1 == 0) begin
		IF2_instr0 = instr0;
		IF2_instr1 = instr1;
	end
	else begin
		if(bubble_ifid_delayed == 1'b1) begin
			IF2_instr0 = 32'b0;
			IF2_instr1 = 32'b0;
		end
		else begin
			IF2_instr0 = delayed_instr0;
			IF2_instr1 = delayed_instr1;
		end
	end

end

reg [31:0] PCPrevious;
// PC adder
// assign PCplus4 = PC + 32'd4;

// Branch signal for new PC
always @(*) begin
	if(int_taken||trap_in_ID)
	begin
		PC_new = trap_vector;
	end
	else if (PCSrc == 1'b0) begin
		if (Jump == 2'b00) begin
			PC_new = PC + ((flushPipeline == 1'b1) ? 32'd0 : 32'd4);
		end
		else if (Jump == 2'b01) begin
			PC_new = JumpAddress0;
		end
		else if (Jump == 2'b10) begin
			PC_new = JumpAddress1;
		end
		else begin
			PC_new = 32'hffffffff;
		end
	end
	else begin
		PC_new = EXMEM_BranchALUOut;
	end
end

assign JumpAddress0 = IFID_PC + signExtend0;
assign JumpAddress1 = IFID_PC + signExtend1;


// IFID pipeline register
always @(posedge clock or negedge reset)
begin 
	if((reset == 1'b0))
	begin
		IFID_PC			<= 32'b0;
		IFID_instr0		<= 32'b0;
		IFID_instr1		<= 32'b0;
	end
	else begin
		// used to hold bubble in the pipeline. You loose an extra cycle here
		// This is so that the instruction memory can notice the jump
		if ((bubble_ifid_delayed||bubble_ifid == 1'b1)) begin
			IFID_instr0		<= 32'b0;
			IFID_instr1		<= 32'b0;
			IFID_PC			<= 32'hffffffff;
		end 
		else if (write_ifid == 1'b1) begin
			IFID_PC			<= PC_IF2;
			IFID_instr0		<= IF2_instr0;
			IFID_instr1		<= IF2_instr1;
		end
	end
end

/***************************** Instruction Decode Unit (ID)  *******************/

// INSTRUCTION 0
assign opcode0		= IFID_instr0[6:0];
// funct 3 is also used for csr operations
assign funct3_0		= IFID_instr0[14:12];
assign funct7_0		= IFID_instr0[31:25];
assign instr0_rs1	= IFID_instr0[19:15];
assign csr_addr0	= IFID_instr0[31:20];
assign instr0_rs2	= IFID_instr0[24:20];
assign instr0_rd	= IFID_instr0[11:7];

// INSTRUCTION 1
assign opcode1		= IFID_instr1[6:0];
// funct 3 is also used for csr operations
assign funct3_1		= IFID_instr1[14:12];
assign funct7_1		= IFID_instr1[31:25];
assign instr1_rs1	= IFID_instr1[19:15];
assign csr_addr1	= IFID_instr1[31:20];
assign instr1_rs2	= IFID_instr1[24:20];
assign instr1_rd	= IFID_instr1[11:7];

// can also probably add illegal instruction checks here as well
// just OR it with syscall and give it to the control stall unit
assign syscall0 = (IDEX_Jump == 2'b00 & IDEX_JumpJALR == 1'b0 & opcode0 == `I_ENV_FORMAT & funct3_0 == 0) ? 1'b1 : 1'b0;
assign syscall1 = (IDEX_Jump == 2'b00 & IDEX_JumpJALR == 1'b0 & opcode1 == `I_ENV_FORMAT & funct3_1 == 0) ? 1'b1 : 1'b0;

always @(*) begin
    // CSR Write for Instruction 0
    if(reg_type_0 == 3'b001) begin
        if(funct3_0[1:0] == 2'b00) begin
            csr_write_allowed_0 = 1'b0;
        end
        else if(funct3_0[1:0] == 2'b01) begin
            csr_write_allowed_0 = 1'b1;
        end
        else begin
            if(instr_rs1_0 == 5'b0) begin
                csr_write_allowed_0 = 1'b0;
            end
            else begin
                csr_write_allowed_0 = 1'b1;
            end
        end
    end
    else begin
        csr_write_allowed_0 = 1'b0;
    end

    // CSR Write for Instruction 1
    if(reg_type_1 == 3'b001) begin
        if(funct3_1[1:0] == 2'b00) begin
            csr_write_allowed_1 = 1'b0;
        end
        else if(funct3_1[1:0] == 2'b01) begin
            csr_write_allowed_1 = 1'b1;
        end
        else begin
            if(instr_rs1_1 == 5'b0) begin
                csr_write_allowed_1 = 1'b0;
            end
            else begin
                csr_write_allowed_1 = 1'b1;
            end
        end
    end
    else begin
        csr_write_allowed_1 = 1'b0;
    end
end

//Sign Extension Unit 0
signExtend signExtendUnit0 (
	.instr(IFID_instr0[31:7]),
	.imm_i(imm_i_0),
	.imm_s(imm_s_0),
	.imm_b(imm_b_0),
	.imm_u(imm_u_0),
	.imm_j(imm_j_0),
	.imm_z(imm_z_0)
);

//Sign Extension Unit 1
signExtend signExtendUnit1 (
	.instr(IFID_instr1[31:7]),
	.imm_i(imm_i_1),
	.imm_s(imm_s_1),
	.imm_b(imm_b_1),
	.imm_u(imm_u_1),
	.imm_j(imm_j_1),
	.imm_z(imm_z_1)
);

// Register file
RegFile cpu_regs (
	.clock(clock),
	.reset(reset),
	
	// Read ports for instruction 0
	.raA_0(instr0_rs1),
	.raB_0(instr0_rs2),
	.floatingID_0(reg_type_0 == 3'b010 || reg_type_0 == 3'b100),
	.rdA_0(rdA_0),
	.rdB_0(rdB_0),

	// Read ports for instruction 1
	.raA_1(instr1_rs1),
	.raB_1(instr1_rs2),
	.floatingID_1(reg_type_1 == 3'b010 || reg_type_1 == 3'b100),
	.rdA_1(rdA_1),
	.rdB_1(rdB_1),

	// load and store instructions access the integer regfile
	// when reading and the fp regfile when storing
	// the regtype 11 is subsequently indicating exactly that

	// Write port for instruction 0
	.wa_0(MEMWB_RegWriteAddr_0),
	.wen_0(MEMWB_RegWrite_0),
	.wd_0(wRegData_0)
	.floatingWB_0((MEMWB_reg_type_0 == 3'b010) || (MEMWB_reg_type_0 == 3'b011) || MEMWB_reg_type_0 == 3'b101),
	
	// Write port for instruction 1
	.wa_1(MEMWB_RegWriteAddr_1),
	.wen_1(MEMWB_RegWrite_1),
	.wd_1(wRegData_1)
	.floatingWB_1((MEMWB_reg_type_1 == 3'b010) || (MEMWB_reg_type_1 == 3'b011) || MEMWB_reg_type_1 == 3'b101),
);




// Sign Extended Signal Selection 0
SignExtendSelector SignExtendSelector0 (
	.out(signExtend0),
	.imm_i(imm_i_0),
	.imm_s(imm_s_0),
	.imm_b(imm_b_0),
	.imm_u(imm_u_0),
	.imm_j(imm_j_0),
	.imm_z(imm_z_0),
	.opcode(opcode0)
);

// Sign Extended Signal Selection 1
SignExtendSelector SignExtendSelector1 (
	.out(signExtend1),
	.imm_i(imm_i_1),
	.imm_s(imm_s_1),
	.imm_b(imm_b_1),
	.imm_u(imm_u_1),
	.imm_j(imm_j_1),
	.imm_z(imm_z_1),
	.opcode(opcode1)
);


// IDEX pipeline register
always @(posedge clock or negedge reset)
begin
	if ((reset == 1'b0)) begin
		IDEX_inA_is_PC_0<= 1'b0;
		IDEX_inA_is_PC_1<= 1'b0;
		IDEX_Jump		<= 2'b00;	//SKEPSH
		IDEX_JumpJALR_0	<= 1'b0;
		IDEX_JumpJALR_1	<= 1'b0;
		IDEX_signExtend0<= 32'b0;
		IDEX_signExtend1<= 32'b0;
		IDEX_instr0_rd	<= 5'b0;
		IDEX_instr1_rd	<= 5'b0;
		IDEX_instr0_rs1	<= 5'b0;
		IDEX_instr1_rs1	<= 5'b0;
		IDEX_instr0_rs2	<= 5'b0;
		IDEX_instr1_rs2	<= 5'b0;
		IDEX_RegDst_0	<= 1'b0;
		IDEX_RegDst_1	<= 1'b0;
		IDEX_EXcntrl_0	<= 3'b0;
		IDEX_EXcntrl_1	<= 3'b0;
		IDEX_ALUSrc_0	<= 1'b0;
		IDEX_ALUSrc_1	<= 1'b0;
		IDEX_Branch_0	<= 1'b0;
		IDEX_Branch_1	<= 1'b0;
		IDEX_MemRead_0	<= 1'b0;
		IDEX_MemRead_1	<= 1'b0;
		IDEX_MemWrite_0	<= 1'b0;
		IDEX_MemWrite_1	<= 1'b0;
		IDEX_MemToReg_0	<= 1'b0;
		IDEX_MemToReg_1	<= 1'b0;
		IDEX_RegWrite_0	<= 1'b0;
		IDEX_RegWrite_1	<= 1'b0;
		IDEX_funct3_0	<= 3'b0;
		IDEX_funct3_1	<= 3'b0;
		IDEX_funct7_0	<= 7'b0;
		IDEX_funct7_1	<= 7'b0;
		IDEX_PC_0		<= 32'b0;
		IDEX_PC_1		<= 32'b0;
		IDEX_rdA_0		<= 32'b0;
		IDEX_rdA_1		<= 32'b0;
		IDEX_rdB_0		<= 32'b0;
		IDEX_rdB_1		<= 32'b0;
		IDEX_reg_type_0	<= 3'b0;
		IDEX_reg_type_1	<= 3'b0;
		IDEX_instr_0	<= 32'b0;
		IDEX_instr_1	<= 32'b0;
		IDEX_csr_addr_0	<= 12'b0;
		IDEX_csr_addr_1	<= 12'b0;
		IDEX_csr_write_allowed_0 <= 1'b0;
		IDEX_csr_write_allowed_1 <= 1'b0;
	end
	else
	begin
		if ((bubble_idex_0)) begin
			IDEX_inA_is_PC_0<= 1'b0;
			IDEX_Jump		<= 2'b00;
			IDEX_JumpJALR_0	<= 1'b0;
			IDEX_signExtend0<= 32'b0;
			IDEX_instr0_rd	<= 5'b0;
			IDEX_instr0_rs1	<= 5'b0;
			IDEX_instr0_rs2	<= 5'b0;
			IDEX_RegDst_0	<= 1'b0;
			IDEX_EXcntrl_0	<= 3'b0;
			IDEX_ALUSrc_0	<= 1'b0;
			IDEX_Branch_0	<= 1'b0;
			IDEX_MemRead_0	<= 1'b0;
			IDEX_MemWrite_0	<= 1'b0;
			IDEX_MemToReg_0	<= 1'b0;
			IDEX_RegWrite_0	<= 1'b0;
			IDEX_funct3_0	<= 3'b0;
			IDEX_funct7_0	<= 7'b0;
			IDEX_rdA_0		<= 32'b0;
			IDEX_rdB_0		<= 32'b0;
			IDEX_reg_type_0	<= 3'b0;
			IDEX_instr_0	<= 32'b0;
			IDEX_csr_addr_0	<= 12'b0;
			IDEX_csr_write_allowed_0 <= 1'b0;
			IDEX_PC_0		<= 32'hffffffff;
		end
		else if (write_idex_0) begin
			IDEX_inA_is_PC_0<= inA_is_PC_0;
			IDEX_Jump		<= Jump;
			IDEX_JumpJALR_0	<= JumpJALR_0;
			IDEX_signExtend0<= signExtend0;
			IDEX_instr0_rd	<= instr0_rd;
			IDEX_instr0_rs1	<= instr0_rs1;
			IDEX_instr0_rs2	<= instr0_rs2;
			IDEX_RegDst_0	<= RegDst_0;
			IDEX_EXcntrl_0	<= EXcntrl_0;
			IDEX_ALUSrc_0	<= ALUSrc_0;
			IDEX_Branch_0	<= Branch_0;
			IDEX_MemRead_0	<= MemRead_0;
			IDEX_MemWrite_0	<= MemWrite_0;
			IDEX_MemToReg_0	<= MemToReg_0;
			IDEX_RegWrite_0	<= RegWrite_0;
			IDEX_funct3_0	<= funct3_0;
			IDEX_funct7_0	<= funct7_0;
			IDEX_PC_0		<= IFID_PC_0;
			IDEX_rdA_0		<= rdA_0;
			IDEX_rdB_0		<= rdB_0;
			// if the exponent is NaN or +-infinity then to propagate the value, turn the other to zero
			// if both are NaN or inf, then keep just one (the extra condition for rdA)
			IDEX_reg_type_0	<= reg_type_0;
			IDEX_instr_0	<= IFID_instr_0;
			IDEX_csr_addr_0	<= csr_addr_0;
			IDEX_csr_write_allowed_0 <= csr_write_allowed_0;
		end

		if ((bubble_idex_1)) begin
			IDEX_inA_is_PC_1<= 1'b0;
			IDEX_Jump		<= 2'b00;
			IDEX_JumpJALR_1	<= 1'b0;
			IDEX_signExtend1<= 32'b0;
			IDEX_instr1_rd	<= 5'b0;
			IDEX_instr1_rs1	<= 5'b0;
			IDEX_instr1_rs2	<= 5'b0;
			IDEX_RegDst_1	<= 1'b0;
			IDEX_EXcntrl_1	<= 3'b0;
			IDEX_ALUSrc_1	<= 1'b0;
			IDEX_Branch_1	<= 1'b0;
			IDEX_MemRead_1	<= 1'b0;
			IDEX_MemWrite_1	<= 1'b0;
			IDEX_MemToReg_1	<= 1'b0;
			IDEX_RegWrite_1	<= 1'b0;
			IDEX_funct3_1	<= 3'b0;
			IDEX_funct7_1	<= 7'b0;
			IDEX_rdA_1		<= 32'b0;
			IDEX_rdB_1		<= 32'b0;
			IDEX_reg_type_1	<= 3'b0;
			IDEX_instr_1	<= 32'b0;
			IDEX_csr_addr_1	<= 12'b0;
			IDEX_csr_write_allowed_1 <= 1'b0;
			IDEX_PC_1		<= 32'hffffffff;
		end
		else if (write_idex_1) begin
			IDEX_inA_is_PC_1<= inA_is_PC_1;
			IDEX_Jump		<= Jump;
			IDEX_JumpJALR_1	<= JumpJALR_1;
			IDEX_signExtend1<= signExtend1;
			IDEX_instr1_rd	<= instr1_rd;
			IDEX_instr1_rs1	<= instr1_rs1;
			IDEX_instr1_rs2	<= instr1_rs2;
			IDEX_RegDst_1	<= RegDst_1;
			IDEX_EXcntrl_1	<= EXcntrl_1;
			IDEX_ALUSrc_1	<= ALUSrc_1;
			IDEX_Branch_1	<= Branch_1;
			IDEX_MemRead_1	<= MemRead_1;
			IDEX_MemWrite_1	<= MemWrite_1;
			IDEX_MemToReg_1	<= MemToReg_1;
			IDEX_RegWrite_1	<= RegWrite_1;
			IDEX_funct3_1	<= funct3_1;
			IDEX_funct7_1	<= funct7_1;
			IDEX_PC_1		<= IFID_PC_1;
			IDEX_rdA_1		<= rdA_1;
			IDEX_rdB_1		<= rdB_1;
			// if the exponent is NaN or +-infinity then to propagate the value, turn the other to zero
			// if both are NaN or inf, then keep just one (the extra condition for rdA)
			IDEX_reg_type_1	<= reg_type_1;
			IDEX_instr_1	<= IFID_instr_1;
			IDEX_csr_addr_1	<= csr_addr_1;
			IDEX_csr_write_allowed_1 <= csr_write_allowed_1;
		end
	end
end

reg [31:0] newmepc;
reg [255*8-1:0] pc_string;
//reg pc_jumped;

localparam MEPC_IDLE = 32'h0;
localparam MEPC_WAITINGJUMP = 32'h1;

reg mepc_state;
always@(posedge clock or negedge reset)begin
	if(reset==1'b0)begin
		pc_string<="Reset";
		newmepc <= 32'h0;
		//pc_jumped <= 1'b0;
		mepc_state <= MEPC_IDLE;
	end
	else
	begin

		case(mepc_state)
			MEPC_IDLE:begin
				if(flushPipeline)
				begin
					if(branch_taken || Jump || EXMEM_JumpJALR)
					begin
						pc_string = "BID Taken";
						newmepc <= PC_new;
					end
					else if(write_pc==1'b0&&IFID_PC!=32'hffffffff)
					begin
						pc_string="stalled due to loadWord";
						newmepc <= IFID_PC;
					end
					else if(PC_IF2!=32'hffffffff)
					begin
						pc_string="IF2 Taken";
						newmepc <= PC_IF2;
					end
					else
					begin
						pc_string="PC Taken";
						newmepc <= PC;
					end
					mepc_state <= MEPC_WAITINGJUMP;
				end
			end
			MEPC_WAITINGJUMP:begin
				if(branch_taken||Jump||EXMEM_JumpJALR)
				begin
					pc_string="Branch Taken";
					newmepc <= PC_new;
				end
				if(flushPipeline==1'b0)
				begin
					mepc_state <= MEPC_IDLE;
				end
			end
		endcase
		// if(branch_taken||Jump||JumpJALR)
		// begin
		// 	pc_jumped <= 1'b1;
		// 	newmepc <= PC_new;
		// end
		// if(flushPipeline)
		// begin
		// 	if(!pc_jumped&&PC_IF2!=32'hffffffff)
		// 	begin
		// 		pc_string="IF2 Taken";
		// 		newmepc <= PC_IF2;
		// 	end
		// end
		// else
		// begin
		// 	pc_jumped <= 1'b0;
		// end
	end
	// if(branch_taken==1'b1)begin
	// 	pc_string="Branch taken";
	// 	newmepc = EXMEM_BranchALUOut;
	// end
	// if(EXMEM_PC!=32'hffffffff&(~EXMEM_MemToReg))begin
	// 	pc_string="EXMEM Taken";
	// 	newmepc = EXMEM_PC;
	// end
	// else if(IDEX_PC!=32'hffffffff)begin
	// 	pc_string="IDEX Taken";
	// 	newmepc = IDEX_PC;
	// end
	// else if(IFID_PC!=32'hffffffff)begin
	// 	pc_string="IFID Taken";
	// 	newmepc = IFID_PC;
	// end
	// else if(PC_IF2 !=32'hffffffff)begin
	// 	pc_string="IF2 Taken";
	// 	newmepc = PC_IF2;
	// end
	// else begin
	// 	pc_string="PC Taken";
	// 	newmepc = PC;
	// end
	// newmepc = PC;
end

wire flushPipeline;

CSRFile csrFile(
	.clock(clock),
	.reset(reset),
	.wen(MEMWB_csr_write_allowed),
	.ren(reg_type==3'b001),	// ALLAGMA *2
	.csrAddr(csr_addr),
	.csrWAddr(MEMWB_csr_addr),
	.wd(WB_csr_data),
	.rd(csr_data),
	.write_pc(write_pc),

	// clic signals
	.PC(PC),
	// maybe check if we are on a branch, if so then we need save the branch
	.IDEX_PC(newmepc),
	.software_interrupt(software_interrupt),
	.timer_interrupt(timer_interrupt),
	.external_interrupt(external_interrupt),
	.syscall(trap_waiting),
	.int_taken(int_taken),
	.trap_in_ID(trap_in_ID),
	.flushPipeline(flushPipeline),
	.trap_vector(trap_vector)
);

// Main Control Unit
control_main control_main (
	.RegDst(RegDst),
	.reg_type(reg_type), //ALLAGMA *2
	.Branch(Branch),
	.MemRead(MemRead),
	.MemWrite(MemWrite),
	.MemToReg(MemToReg),
	.ALUSrc(ALUSrc),
	.RegWrite(RegWrite),
	.Jump(Jump),
	.JumpJALR(JumpJALR),
	.inA_is_PC(inA_is_PC),
	.EXcntrl(EXcntrl),
	.funct7(funct7), // ALLAGMA *2
	.opcode(opcode)	// ALLAGMA *2
);

wire [31:0] div_rdA, div_rdB;
//division FSM
// Control Unit that generates stalls and bubbles to pipeline stages
control_stall_id control_stall_id (
	.bubble_ifid	(bubble_ifid),
	.bubble_idex	(bubble_idex),
	.bubble_exmem	(bubble_exmem),
	.write_ifid		(write_ifid),
	.write_idex		(write_idex),
	.write_exmem	(write_exmem),
	.write_memwb	(write_memwb),
	.write_pc		(write_pc),
	.instr_en		(instr_en),
	.trap_waiting	(trap_waiting),
	.ifid_rs		(instr_rs1),
	.ifid_rt		(instr_rs2),
	.idex_rd		(IDEX_instr_rd),
	.memRead		(MemRead),
	.idex_memWrite	(IDEX_MemWrite),
	.idex_memread	(IDEX_MemRead),
	.Jump			(Jump),
	.IDEX_Branch	(IDEX_Branch),
	.EXMEM_Branch	(EXMEM_Branch),
	.syscall		(syscall),
	.trap_in_ID		(trap_in_ID),
	.int_trap		(int_taken),
	.flushPipeline	(flushPipeline),
	.memReady		(memReady),
	.trapdiv(trapdiv),
	.divcy((local_divcy != 32)),
	.PCSrc			(PCSrc),
	.reg_type(reg_type)	//ALLAGMA *2
	);

/************************ Execution Unit (EX)  ***********************************/


// ALU input A_0
always @(*) begin
    if (IDEX_inA_is_PC_0 == 1'b1)
        ALUInA_0 = IDEX_PC_0;
    else
        ALUInA_0 = bypassOutA_0;
end

// ALU input A_1
always @(*) begin
    if (IDEX_inA_is_PC_1 == 1'b1)
        ALUInA_1 = IDEX_PC_1;
    else
        ALUInA_1 = bypassOutA_1;
end

// ALU input B_0
always @(*) begin
    if (IDEX_Jump != 2'b00 || IDEX_JumpJALR_0 == 1'b1)
        ALUInB_0 = 32'd4;
    else if (IDEX_ALUSrc_0 == 1'b0)
        ALUInB_0 = bypassOutB_0;
    else
        ALUInB_0 = IDEX_signExtend_0;
end

// ALU input B_1
always @(*) begin
    if (IDEX_Jump != 2'b00 || IDEX_JumpJALR_1 == 1'b1)
        ALUInB_1 = 32'd4;
    else if (IDEX_ALUSrc_1 == 1'b0)
        ALUInB_1 = bypassOutB_1;
    else
        ALUInB_1 = IDEX_signExtend_1;
end

// Branch Target Calculation
assign BranchInA_0 = (IDEX_JumpJALR_0 == 1'b1) ? bypassOutA_0 : IDEX_PC_0;
assign BranchInA_1 = (IDEX_JumpJALR_1 == 1'b1) ? bypassOutA_1 : IDEX_PC_1;

assign BranchALUOut_0 = BranchInA_0 + IDEX_signExtend_0;
assign BranchALUOut_1 = BranchInA_1 + IDEX_signExtend_1;

// ALU 0
ALUCPU cpu_alu_0(		
	.out(ALUOut_0),
	.zero(Zero_0),	
	.overflow(overflow_0),
	.inA(ALUInA_0),
	.inB(ALUInB_0),
	.op(ALUOp_0)
);

// ALU 1
ALUCPU cpu_alu_1(		
	.out(ALUOut_1),
	.zero(Zero_1),	
	.overflow(overflow_1),
	.inA(ALUInA_1),
	.inB(ALUInB_1),
	.op(ALUOp_1)
);

assign RegWriteAddr_0 = (IDEX_RegDst_0 == 1'b0) ? IDEX_instr0_rs2 : IDEX_instr0_rd;
assign RegWriteAddr_1 = (IDEX_RegDst_1 == 1'b0) ? IDEX_instr1_rs2 : IDEX_instr1_rd;

fpu FPU_0(
	.FPUOp(FPUOp_0),
	.number1((ALUInA_0[30:23] == 8'hFF) ? ((ALUInB_0[30:23]!= 8'hFF) ? 0 : ALUInA_0) : ALUInA_0),
	.number2(ALUInB_0[30:23] == 8'hFF ? 0 : ALUInB_0),
	.out(FPUOut_0)
);

fpu FPU_1(
	.FPUOp(FPUOp_1),
	.number1((ALUInA_1[30:23] == 8'hFF) ? ((ALUInB_1[30:23]!= 8'hFF) ? 0 : ALUInA_1) : ALUInA_1),
	.number2(ALUInB_1[30:23] == 8'hFF ? 0 : ALUInB_1),
	.out(FPUOut_1)
);

// DIVISION UNIT
division_unit DU_0(
	.clk(clock),
	.reset(!reset),
	.ALUOp(ALUOp_0),
	.cpu_divcy(local_divcy_0),
	.du_divcy(divcy_0),
	.trapdiv(trapdiv_0),
	.inA(ALUInA_0), //otherwise IDEX_rdA
	.inB(ALUInB_0), // otherwise IDEX_rdB
	.rem(divrem_0),
	.quo(divres_0)	
);

division_unit DU_1(
	.clk(clock),
	.reset(!reset),
	.ALUOp(ALUOp_1),
	.cpu_divcy(local_divcy_1),
	.du_divcy(divcy_1),
	.trapdiv(trapdiv_1),
	.inA(ALUInA_1), //otherwise IDEX_rdA
	.inB(ALUInB_1), // otherwise IDEX_rdB
	.rem(divrem_1),
	.quo(divres_1)
);

// EXMEM pipeline register
always @(posedge clock or negedge reset)
begin
	if(local_divcy == 6'd32 && divcy != 6'd32)begin
		local_divcy <= divcy;
	end

	if(local_divcy != 6'd32)begin
		local_divcy <= local_divcy-1;
	end

	if(local_divcy == 6'd0)begin
		local_divcy <= 6'd32;
	end

	if ((reset == 1'b0)) begin
		local_divcy_0		<= 6'd32;
		local_divcy_1		<= 6'd32;
		EXMEM_ALUOut_0		<= 32'b0;
		EXMEM_ALUOut_1		<= 32'b0;
		EXMEM_JumpJALR_0	<= 1'b0;
		EXMEM_JumpJALR_1	<= 1'b0;
		EXMEM_BranchALUOut_0<= 32'b0;
		EXMEM_BranchALUOut_1<= 32'b0;
		EXMEM_RegWriteAddr_0<= 5'b0;
		EXMEM_RegWriteAddr_1<= 5'b0;
		EXMEM_MemWriteData_0<= 32'b0;
		EXMEM_MemWriteData_1<= 32'b0;
		EXMEM_Zero_0		<= 1'b0;
		EXMEM_Zero_1		<= 1'b0;
		EXMEM_Branch_0		<= 1'b0;
		EXMEM_Branch_1		<= 1'b0;
		EXMEM_MemRead_0		<= 1'b0;
		EXMEM_MemRead_1		<= 1'b0;
		EXMEM_MemWrite_0	<= 1'b0;
		EXMEM_MemWrite_1	<= 1'b0;
		EXMEM_MemToReg_0	<= 1'b0;
		EXMEM_MemToReg_1	<= 1'b0;
		EXMEM_RegWrite_0	<= 1'b0;
		EXMEM_RegWrite_1	<= 1'b0;
		EXMEM_funct3_0		<= 3'b0;
		EXMEM_funct3_1		<= 3'b0;
		EXMEM_csr_data_0	<= 32'b0;
		EXMEM_csr_data_1	<= 32'b0;
		EXMEM_reg_type_0	<= 3'b000;
		EXMEM_reg_type_1	<= 3'b000;
		EXMEM_csr_addr_0	<= 12'b0;
		EXMEM_csr_addr_1	<= 12'b0;
		EXMEM_csr_write_allowed_0 <= 1'b0;
		EXMEM_csr_write_allowed_1 <= 1'b0;
		EXMEM_PC_0			<= 32'hffffffff;
		EXMEM_PC_1			<= 32'hffffffff;
		EXMEM_instr_0		<= 32'b0;
		EXMEM_instr_1		<= 32'b0;
	end 
	else
	begin
		if ((bubble_exmem_0)) begin
			EXMEM_ALUOut_0		<= 32'b0;
			EXMEM_JumpJALR_0	<= 1'b0;
			EXMEM_BranchALUOut_0<= 32'b0;
			EXMEM_RegWriteAddr_0<= 5'b0;
			EXMEM_MemWriteData_0<= 32'b0;
			EXMEM_Zero_0		<= 1'b0;
			EXMEM_Branch_0		<= 1'b0;
			EXMEM_MemRead_0		<= 1'b0;
			EXMEM_MemWrite_0	<= 1'b0;
			EXMEM_MemToReg_0	<= 1'b0;
			EXMEM_RegWrite_0	<= 1'b0;
			EXMEM_funct3_0		<= 3'b0;
			EXMEM_csr_data_0	<= 32'b0;
			EXMEM_reg_type_0	<= 3'b000;
			EXMEM_csr_addr_0	<= 12'b0;
			EXMEM_csr_write_allowed_0 <= 1'b0;
			EXMEM_PC_0			<= 32'hffffffff;
			EXMEM_instr_0		<= 32'b0;
		end 
		else if (write_exmem_0) begin
			EXMEM_ALUOut_0		<= divres_0 ? divres_0 : ((IDEX_reg_type_0 == 3'b010) ? FPUOut_0 : ALUOut_0);
			EXMEM_JumpJALR_0	<= IDEX_JumpJALR_0;
			EXMEM_BranchALUOut_0<= BranchALUOut_0;
			EXMEM_RegWriteAddr_0<= RegWriteAddr_0;
			EXMEM_MemWriteData_0<= bypassOutB_0;
			EXMEM_Zero_0		<= Zero_0;
			EXMEM_Branch_0		<= IDEX_Branch_0;
			EXMEM_MemRead_0		<= IDEX_MemRead_0;
			EXMEM_MemWrite_0	<= IDEX_MemWrite_0;
			EXMEM_MemToReg_0	<= IDEX_MemToReg_0;
			EXMEM_RegWrite_0	<= IDEX_RegWrite_0;
			EXMEM_funct3_0		<= IDEX_funct3_0;
			EXMEM_csr_data_0	<= csr_data_0;
			EXMEM_reg_type_0	<= IDEX_reg_type_0;
			EXMEM_csr_addr_0	<= IDEX_csr_addr_0;
			EXMEM_csr_write_allowed_0 <= IDEX_csr_write_allowed_0;
			EXMEM_PC_0			<= IDEX_PC_0;
			EXMEM_instr_0		<= IDEX_instr_0;
		end

		if ((bubble_exmem_1)) begin
			EXMEM_ALUOut_1		<= 32'b0;
			EXMEM_JumpJALR_1	<= 1'b0;
			EXMEM_BranchALUOut_1<= 32'b0;
			EXMEM_RegWriteAddr_1<= 5'b0;
			EXMEM_MemWriteData_1<= 32'b0;
			EXMEM_Zero_1		<= 1'b0;
			EXMEM_Branch_1		<= 1'b0;
			EXMEM_MemRead_1		<= 1'b0;
			EXMEM_MemWrite_1	<= 1'b0;
			EXMEM_MemToReg_1	<= 1'b0;
			EXMEM_RegWrite_1	<= 1'b0;
			EXMEM_funct3_1		<= 3'b0;
			EXMEM_csr_data_1	<= 32'b0;
			EXMEM_reg_type_1	<= 3'b000;
			EXMEM_csr_addr_1	<= 12'b0;
			EXMEM_csr_write_allowed_1 <= 1'b0;
			EXMEM_PC_1			<= 32'hffffffff;
			EXMEM_instr_1		<= 32'b0;
		end 
		else if (write_exmem_1) begin
			EXMEM_ALUOut_1		<= divres_1 ? divres_1 : ((IDEX_reg_type_1 == 3'b010) ? FPUOut_1 : ALUOut_1);
			EXMEM_JumpJALR_1	<= IDEX_JumpJALR_1;
			EXMEM_BranchALUOut_1<= BranchALUOut_1;
			EXMEM_RegWriteAddr_1<= RegWriteAddr_1;
			EXMEM_MemWriteData_1<= bypassOutB_1;
			EXMEM_Zero_1		<= Zero_1;
			EXMEM_Branch_1		<= IDEX_Branch_1;
			EXMEM_MemRead_1		<= IDEX_MemRead_1;
			EXMEM_MemWrite_1	<= IDEX_MemWrite_1;
			EXMEM_MemToReg_1	<= IDEX_MemToReg_1;
			EXMEM_RegWrite_1	<= IDEX_RegWrite_1;
			EXMEM_funct3_1		<= IDEX_funct3_1;
			EXMEM_csr_data_1	<= csr_data_1;
			EXMEM_reg_type_1	<= IDEX_reg_type_1;
			EXMEM_csr_addr_1	<= IDEX_csr_addr_1;
			EXMEM_csr_write_allowed_1 <= IDEX_csr_write_allowed_1;
			EXMEM_PC_1			<= IDEX_PC_1;
			EXMEM_instr_1		<= IDEX_instr_1;
		end
	end
end

// ALU control unit
// Determines the ALU operation based on the instruction
control_ex control_ex_0(
	.ALUOp(ALUOp_0),
	.FPUOp(FPUOp_0), 
	.EXcntrl(IDEX_EXcntrl_0), 
	.csr_immidiate(csr_immidiate_0),
	.rs2(IDEX_instr0_rs2),
	.funct3(IDEX_funct3_0), 
	.funct7(IDEX_funct7_0)
);

control_ex control_ex_1(
	.ALUOp(ALUOp_1),
	.FPUOp(FPUOp_1), 
	.EXcntrl(IDEX_EXcntrl_1), 
	.csr_immidiate(csr_immidiate_1),
	.rs2(IDEX_instr1_rs2),
	.funct3(IDEX_funct3_1), 
	.funct7(IDEX_funct7_1)
);

// Bypass control
// Controls what the ALU inputs are
control_bypass_ex control_bypass_ex(
	.bypassOutA(bypassOutA),
	.bypassOutB(bypassOutB),
	.idex_rs1(IDEX_instr_rs1), 
	.idex_rs2(IDEX_instr_rs2),
	.idex_rd(IDEX_instr_rd),
	.idex_reg_type(IDEX_reg_type),	// ALLAGMA *2
	.exmem_reg_type(EXMEM_reg_type), // ALLAGMA *2
	.memwb_reg_type(MEMWB_reg_type), // ALLAGMA *2
	.idex_rdA(IDEX_rdA),
	.idex_rdB(IDEX_rdB),
	.wRegData(wRegData),
	.EXMEM_ALUOut(EXMEM_ALUOut),
	.idex_csr_addr(IDEX_csr_addr),
	.exmem_csr_addr(EXMEM_csr_addr),
	.memwb_csr_addr(MEMWB_csr_addr),
	.csr_data(csr_data),
	.WB_csr_data(WB_csr_data),
	.csr_immidiate(csr_immidiate),
	.exmem_csr_write_allowed(EXMEM_csr_write_allowed),
	.memwb_csr_write_allowed(MEMWB_csr_write_allowed),
	.exmem_rd(EXMEM_RegWriteAddr), 
	.memwb_rd(MEMWB_RegWriteAddr),
	.exmem_regwrite(EXMEM_RegWrite), 
	.memwb_regwrite(MEMWB_RegWrite)
);


/*********************************** Memory Unit (MEM)  ********************************************/
mem_write_selector mem_write_selector_0(
	.mem_select(EXMEM_funct3_0),	// ALLAGMA *2
	.ALUin(EXMEM_MemWriteData_0),
	.offset(EXMEM_ALUOut_0[1:0]),
	.byte_select_vector(byte_select_vector_0),
	.out(MemWriteData_0)
);

mem_write_selector mem_write_selector_1(
	.mem_select(EXMEM_funct3_1),	// ALLAGMA *2
	.ALUin(EXMEM_MemWriteData_1),
	.offset(EXMEM_ALUOut_1[1:0]),
	.byte_select_vector(byte_select_vector_1),
	.out(MemWriteData_1)
);

// MEMWB pipeline register
always @(posedge clock or negedge reset)
begin 
	if (reset == 1'b0) begin
		MEMWB_DMemOut_0		<= 32'b0;
		MEMWB_DMemOut_1		<= 32'b0;
		MEMWB_ALUOut_0		<= 32'b0;
		MEMWB_ALUOut_1		<= 32'b0;
		MEMWB_RegWriteAddr_0<= 5'b0;
		MEMWB_RegWriteAddr_1<= 5'b0;
		MEMWB_MemToReg_0	<= 1'b0;
		MEMWB_MemToReg_1	<= 1'b0;
		MEMWB_RegWrite_0	<= 1'b0;
		MEMWB_RegWrite_1	<= 1'b0;
		MEMWB_funct3_0		<= 3'b0;
		MEMWB_funct3_1		<= 3'b0;
		MEMWB_csr_data_0	<= 32'b0;
		MEMWB_csr_data_1	<= 32'b0;
		MEMWB_reg_type_0	<= 3'b000;
		MEMWB_reg_type_1	<= 3'b000;
		MEMWB_csr_addr_0	<= 12'b0;
		MEMWB_csr_addr_1	<= 12'b0;
		MEMWB_csr_write_allowed_0 <= 1'b0;
		MEMWB_csr_write_allowed_1 <= 1'b0;
		MEMWB_PC_0			<= 32'b0;
		MEMWB_PC_1			<= 32'b0;
		MEMWB_instr_0		<= 32'b0;
		MEMWB_instr_1		<= 32'b0;
	end 
	else 
	begin
		if(bubble_memwb_0) begin
			MEMWB_DMemOut_0		<= 32'b0;
			MEMWB_ALUOut_0		<= 32'b0;
			MEMWB_RegWriteAddr_0<= 5'b0;
			MEMWB_MemToReg_0	<= 1'b0;
			MEMWB_RegWrite_0	<= 1'b0;
			MEMWB_funct3_0		<= 3'b0;
			MEMWB_csr_data_0	<= 32'b0;
			MEMWB_reg_type_0	<= 3'b000;
			MEMWB_csr_addr_0	<= 12'b0;
			MEMWB_csr_write_allowed_0 <= 1'b0;
			MEMWB_PC_0			<= 32'hffffffff;
			MEMWB_instr_0		<= 32'b0;
		end 
		else if (write_memwb_0) begin
			MEMWB_DMemOut_0		<= DMemOut_0;
			MEMWB_ALUOut_0		<= EXMEM_ALUOut_0;
			MEMWB_RegWriteAddr_0<= EXMEM_RegWriteAddr_0;
			MEMWB_MemToReg_0	<= EXMEM_MemToReg_0;
			MEMWB_RegWrite_0	<= EXMEM_RegWrite_0;
			MEMWB_funct3_0		<= EXMEM_funct3_0;
			MEMWB_csr_data_0	<= EXMEM_csr_data_0;
			MEMWB_reg_type_0	<= EXMEM_reg_type_0;
			MEMWB_csr_addr_0	<= EXMEM_csr_addr_0;
			MEMWB_csr_write_allowed_0 <= EXMEM_csr_write_allowed_0;
			MEMWB_PC_0			<= EXMEM_PC_0;
			MEMWB_instr_0		<= EXMEM_instr_0;
		end

		if(bubble_memwb_1) begin
			MEMWB_DMemOut_1		<= 32'b0;
			MEMWB_ALUOut_1		<= 32'b0;
			MEMWB_RegWriteAddr_1<= 5'b0;
			MEMWB_MemToReg_1	<= 1'b0;
			MEMWB_RegWrite_1	<= 1'b0;
			MEMWB_funct3_1		<= 3'b0;
			MEMWB_csr_data_1	<= 32'b0;
			MEMWB_reg_type_1	<= 3'b000;
			MEMWB_csr_addr_1	<= 12'b0;
			MEMWB_csr_write_allowed_1 <= 1'b0;
			MEMWB_PC_1			<= 32'hffffffff;
			MEMWB_instr_1		<= 32'b0;
		end 
		else if (write_memwb_1) begin
			MEMWB_DMemOut_1		<= DMemOut_1;
			MEMWB_ALUOut_1		<= EXMEM_ALUOut_1;
			MEMWB_RegWriteAddr_1<= EXMEM_RegWriteAddr_1;
			MEMWB_MemToReg_1	<= EXMEM_MemToReg_1;
			MEMWB_RegWrite_1	<= EXMEM_RegWrite_1;
			MEMWB_funct3_1		<= EXMEM_funct3_1;
			MEMWB_csr_data_1	<= EXMEM_csr_data_1;
			MEMWB_reg_type_1	<= EXMEM_reg_type_1;
			MEMWB_csr_addr_1	<= EXMEM_csr_addr_1;
			MEMWB_csr_write_allowed_1 <= EXMEM_csr_write_allowed_1;
			MEMWB_PC_1			<= EXMEM_PC_1;
			MEMWB_instr_1		<= EXMEM_instr_1;
		end
	end
end

// Branch control unit
control_branch control_branch_0 (
	.branch_taken(branch_taken_0),
	.funct3(EXMEM_funct3_0),
	.Branch(EXMEM_Branch_0),
	.zero(EXMEM_Zero_0),
	.sign(EXMEM_ALUOut_0[31])
);

control_branch control_branch_1 (
	.branch_taken(branch_taken_1),
	.funct3(EXMEM_funct3_1),
	.Branch(EXMEM_Branch_1),
	.zero(EXMEM_Zero_1),
	.sign(EXMEM_ALUOut_1[31])
);

assign PCSrc_0 = (EXMEM_JumpJALR_0) ? 1'b1 : branch_taken_0;
assign PCSrc_1 = (EXMEM_JumpJALR_1) ? 1'b1 : branch_taken_1;

/**************************** WriteBack Unit (WB) **************************/  
mem_read_selector mem_read_selector_0 (
	.mem_select(MEMWB_funct3_0),
	.DMemOut(MEMWB_DMemOut_0),
	.byte_index(MEMWB_ALUOut_0[1:0]),
	.out(MemOut_0)
);

mem_read_selector mem_read_selector_1 (
	.mem_select(MEMWB_funct3_1),
	.DMemOut(MEMWB_DMemOut_1),
	.byte_index(MEMWB_ALUOut_1[1:0]),
	.out(MemOut_1)
);

always @(*) begin
	if (MEMWB_reg_type_0 != 3'b001) begin
		// if we are not writing to memory get the data from the ALU
		if (MEMWB_MemToReg_0 == 1'b0) begin
			wRegData_0 = MEMWB_ALUOut_0;
		// if we are writing to memory get the data from the memory
		end else begin
			wRegData_0 = MemOut_0;
		end
	end else begin
		wRegData_0 = MEMWB_csr_data_0;
	end

	if (MEMWB_reg_type_1 != 3'b001) begin
		// if we are not writing to memory get the data from the ALU
		if (MEMWB_MemToReg_1 == 1'b0) begin
			wRegData_1 = MEMWB_ALUOut_1;
		// if we are writing to memory get the data from the memory
		end else begin
			wRegData_1 = MemOut_1;
		end
	end else begin
		wRegData_1 = MEMWB_csr_data_1;
	end
end

always @(*)
begin 
	if (write_memwb_0 == 1'b1) begin
		// if we are not writing to memory get the data from the ALU
		if (MEMWB_MemToReg_0 == 1'b0) begin
			WB_csr_data_0 = MEMWB_ALUOut_0;
		// if we are writing to memory get the data from the memory
		end else begin
			WB_csr_data_0 = MemOut_0;
		end
	end
	else begin
		WB_csr_data_0 = 0;
	end

	if (write_memwb_1 == 1'b1) begin
		// if we are not writing to memory get the data from the ALU
		if (MEMWB_MemToReg_1 == 1'b0) begin
			WB_csr_data_1 = MEMWB_ALUOut_1;
		// if we are writing to memory get the data from the memory
		end else begin
			WB_csr_data_1 = MemOut_1;
		end
	end
	else begin
		WB_csr_data_1 = 0;
	end
end

endmodule
