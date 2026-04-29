`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif

/*
 * FIX CSR BYPASSING LOGIC FOR OPERAND B
 */


/***************** Control Module for Bypass Detection in EX Pipe Stage *****************/

/**
 * Module: control_bypass_ex
 * Purpose: Implements bypassing logic in the execute stage of a pipeline to avoid data hazards.
 *          Determines the correct source for the operands by forwarding data from previous stages.
 */
module control_bypass_ex(
    output reg [31:0] bypassOutA_0,     // Bypassed or original operand A
	output reg [31:0] bypassOutA_1,
    output reg [31:0] bypassOutB_0,     // Bypassed or original operand B
	output reg [31:0] bypassOutB_1,
    input [4:0] idex_rs1_0,             // Source register 1 address from ID/EX stage
	input [4:0] idex_rs1_1,
    input [4:0] idex_rs2_0,             // Source register 2 address from ID/EX stage
	input [4:0] idex_rs2_1,
    input [4:0] idex_rd_0,              // Destination register address from ID/EX stage
	input [4:0] idex_rd_1,
    input [2:0] idex_reg_type_0,        // Type of the register (general or CSR)
	input [2:0] idex_reg_type_1,
    input [2:0] exmem_reg_type_0,       // Type of the register (general or CSR)
	input [2:0] exmem_reg_type_1,
    input [2:0] memwb_reg_type_0,       // Type of the register (general or CSR)
	input [2:0] memwb_reg_type_1,
    input [31:0] idex_rdA_0,            // Operand A from ID/EX stage
	input [31:0] idex_rdA_1,
    input [31:0] idex_rdB_0,            // Operand B from ID/EX stage
	input [31:0] idex_rdB_1,
    input [31:0] wRegData_0,            // Writeback data from MEM/WB stage
	input [31:0] wRegData_1,
    input [31:0] EXMEM_ALUOut_0,        // ALU output from EX/MEM stage
	input [31:0] EXMEM_ALUOut_1,
    input [31:0] csr_data_0,              // Data from CSR
	input [31:0] csr_data_1,
    input [31:0] WB_csr_data_0,            // Data to be written to csr
	input [31:0] WB_csr_data_1,
    input [31:0] idex_csr_addr_0,            // Address for CSR
	input [31:0] idex_csr_addr_1,
    input [31:0] exmem_csr_addr_0,            // Address for CSR
	input [31:0] exmem_csr_addr_1,
    input [31:0] memwb_csr_addr_0,            // Address for CSR
	input [31:0] memwb_csr_addr_1,
    input csr_immidiate_0,              // CSR Value originates from Immidiate
	input csr_immidiate_1,
	input exmem_csr_write_allowed_0,
	input exmem_csr_write_allowed_1,
	input memwb_csr_write_allowed_0,
	input memwb_csr_write_allowed_1,
    input [4:0] exmem_rd_0,             // Destination register address from EX/MEM stage
	input [4:0] exmem_rd_1,
    input [4:0] memwb_rd_0,             // Destination register address from MEM/WB stage
	input [4:0] memwb_rd_1,
	input idex_regwrite_0,			 // Write enable signal for ID/EX stage
    input exmem_regwrite_0,             // Write enable signal for EX/MEM stage
	input exmem_regwrite_1,
    input memwb_regwrite_0,             // Write enable signal for MEM/WB stage
	input memwb_regwrite_1
);

// Internal registers to hold bypass selection signals
reg [2:0] bypassA_0; // Bypass selector for Operand A
reg [2:0] bypassA_1;
reg [2:0] bypassB_0; // Bypass selector for Operand B
reg [2:0] bypassB_1; 

// WAY 0 BYPASS A LOGIC //

always @(*) begin
	if (exmem_regwrite_1 == 1'b1 && exmem_rd_1 != 5'b0 && exmem_rd_1 == idex_rs1_0) begin
		bypassA_0 = 3'b001; // Forward data from EX/MEM stage way1
	end
	else if (exmem_regwrite_0 == 1'b1 && exmem_rd_0 != 5'b0 && exmem_rd_0 == idex_rs1_0) begin
		bypassA_0 = 3'b010; // Forward data from EX/MEM stage way0
	end
	else if (memwb_regwrite_1 == 1'b1 && memwb_rd_1 != 5'b0 && memwb_rd_1 == idex_rs1_0) begin
		bypassA_0 = 3'b011; // Forward data from MEM/WB stage way1
	end
	else if (memwb_regwrite_0 == 1'b1 && memwb_rd_0 != 5'b0 && memwb_rd_0 == idex_rs1_0) begin
		bypassA_0 = 3'b100; // Forward data from MEM/WB stage way0
	end
	else begin
		bypassA_0 = 3'b000; // No forwarding, use ID/EX stage value
	end
end

// WAY 1 BYPASS A LOGIC //

always @(*) begin
	if (idex_regwrite_0 == 1'b1 && idex_rd_0 != 5'b0 && idex_rd_0 == idex_rs1_1) begin
		bypassA_1 = 3'b101; // Forward data from way0 stage way1
	end
	else if (exmem_regwrite_1 == 1'b1 && exmem_rd_1 != 5'b0 && exmem_rd_1 == idex_rs1_1) begin
		bypassA_1 = 3'b001; // Forward data from EX/MEM stage way1
	end
	else if (exmem_regwrite_0 == 1'b1 && exmem_rd_0 != 5'b0 && exmem_rd_0 == idex_rs1_1) begin
		bypassA_1 = 3'b010; // Forward data from EX/MEM stage way0
	end
	else if (memwb_regwrite_1 == 1'b1 && memwb_rd_1 != 5'b0 && memwb_rd_1 == idex_rs1_1) begin
		bypassA_1 = 3'b011; // Forward data from MEM/WB stage way1
	end
	else if (memwb_regwrite_0 == 1'b1 && memwb_rd_0 != 5'b0 && memwb_rd_0 == idex_rs1_1) begin
		bypassA_1 = 3'b100; // Forward data from MEM/WB stage way0
	end
	else begin
		bypassA_1 = 3'b000; // No forwarding, use ID/EX stage value
	end
end

// WAY 0 BYPASS B LOGIC //

always @(*) begin
	if(idex_reg_type_0 == 3'b001)begin
		if (exmem_regwrite == 1'b1 && exmem_rd != 5'b0 && exmem_csr_addr == idex_csr_addr) begin
			bypassB_0 = 2'b10; // Forward data from EX/MEM stage
		end
		else if (memwb_regwrite == 1'b1 && memwb_rd != 5'b0 && memwb_csr_addr == idex_csr_addr) begin
			bypassB_0 = 2'b01; // Forward data from MEM/WB stage
		end
		else begin
			bypassB_0 = 2'b00; // No forwarding, use ID/EX stage value
		end
	end
	else begin
		if (exmem_regwrite_1 == 1'b1 && exmem_rd_1 != 5'b0 && exmem_rd_1 == idex_rs2_0 && exmem_reg_type_1 == idex_reg_type_0) begin
			bypassB_0 = 3'b001; // Forward data from EX/MEM stage way1
		end
		else if (exmem_regwrite_0 == 1'b1 && exmem_rd_0 != 5'b0 && exmem_rd_0 == idex_rs2_0 && exmem_reg_type_0 == idex_reg_type_0) begin
			bypassB_0 = 3'b010; // Forward data from EX/MEM stage way0
		end
		else if (memwb_regwrite_1 == 1'b1 && memwb_rd_1 != 5'b0 && memwb_rd_1 == idex_rs2_0 && ((memwb_reg_type_1 == idex_reg_type_0) ||((memwb_reg_type_1 == 3'b011) && (idex_reg_type_0 == 3'b010)))) begin
			bypassB_0 = 3'b011; // Forward data from MEM/WB stage way1
		end
		else if (memwb_regwrite_0 == 1'b1 && memwb_rd_0 != 5'b0 && memwb_rd_0 == idex_rs2_0 && ((memwb_reg_type_0 == idex_reg_type_0) ||((memwb_reg_type_0 == 3'b011) && (idex_reg_type_0 == 3'b010)))) begin
			bypassB_0 = 3'b100; // Forward data from MEM/WB stage way0
		end
		else begin
			bypassB_0 = 3'b000; // No forwarding, use ID/EX stage value
		end
	end
end

// WAY 1 BYPASS B LOGIC //

always @(*) begin
	if(idex_reg_type_1 == 3'b001)begin
		if (exmem_regwrite == 1'b1 && exmem_rd != 5'b0 && exmem_csr_addr == idex_csr_addr) begin
			bypassB_1 = 2'b10; // Forward data from EX/MEM stage
		end
		else if (memwb_regwrite == 1'b1 && memwb_rd != 5'b0 && memwb_csr_addr == idex_csr_addr) begin
			bypassB_1 = 2'b01; // Forward data from MEM/WB stage
		end
		else begin
			bypassB_1 = 2'b00; // No forwarding, use ID/EX stage value
		end
	end
	else begin
		if (idex_regwrite_0 == 1'b1 && idex_rd_0 != 5'b0 && idex_rd_0 == idex_rs2_1) begin
			bypassB_1 = 3'b101; // Forward data from way0 to way1 in ID/EX stage
		end
		else if (exmem_regwrite_1 == 1'b1 && exmem_rd_1 != 5'b0 && exmem_rd_1 == idex_rs2_1 && exmem_reg_type_1 == idex_reg_type_1) begin
			bypassB_1 = 3'b001; // Forward data from EX/MEM stage way1
		end
		else if (exmem_regwrite_0 == 1'b1 && exmem_rd_0 != 5'b0 && exmem_rd_0 == idex_rs2_1 && exmem_reg_type_0 == idex_reg_type_1) begin
			bypassB_1 = 3'b010; // Forward data from EX/MEM stage way0
		end
		else if (memwb_regwrite_1 == 1'b1 && memwb_rd_1 != 5'b0 && memwb_rd_1 == idex_rs2_1 && ((memwb_reg_type_1 == idex_reg_type_1) ||((memwb_reg_type_1 == 3'b011) && (idex_reg_type_1 == 3'b010)))) begin
			bypassB_1 = 3'b011; // Forward data from MEM/WB stage way1
		end
		else if (memwb_regwrite_0 == 1'b1 && memwb_rd_0 != 5'b0 && memwb_rd_0 == idex_rs2_1 && ((memwb_reg_type_0 == idex_reg_type_1) ||((memwb_reg_type_0 == 3'b011) && (idex_reg_type_1 == 3'b010)))) begin
			bypassB_1 = 3'b100; // Forward data from MEM/WB stage way0
		end
		else begin
			bypassB_1 = 3'b000; // No forwarding, use ID/EX stage value
		end
	end
end

//--- Select the correct source for Operand A based on bypass logic ---//

// WAY A 0 //

always @(*) begin
	if(csr_immidiate_0 == 1'b1) begin
		bypassOutA_0 = idex_rs1_0;
	end
	else begin
		// No intra forwarding for way0 as it is the earliest stage
		case (bypassA_0)
			3'b001: bypassOutA_0 = EXMEM_ALUOut_1;			// Forward data from EX/MEM stage way1
			3'b010: bypassOutA_0 = EXMEM_ALUOut_0;			// Forward data from EX/MEM stage way0
			3'b011: bypassOutA_0 = (idex_reg_type_0 == 3'b001) ? WB_csr_data_1 : wRegData_1;	// Forward data from MEM/WB stage way1
			3'b100: bypassOutA_0 = (idex_reg_type_0 == 3'b001) ? WB_csr_data_0 : wRegData_0;	// Forward data from MEM/WB stage way0
			default: bypassOutA_0 = idex_rdA_0;				// Use original ID/EX value
		endcase
	end
end

// WAY A 1 //

always @(*) begin
	if(csr_immidiate_1 == 1'b1) begin
		bypassOutA_1 = idex_rs1_1;
	end
	else begin
		case (bypassA_1)
			3'b001: bypassOutA_1 = EXMEM_ALUOut_1;			// Forward data from EX/MEM stage way1
			3'b010: bypassOutA_1 = EXMEM_ALUOut_0;			// Forward data from EX/MEM stage way0
			3'b011: bypassOutA_1 = (idex_reg_type_1 == 3'b001) ? WB_csr_data_1 : wRegData_1;	// Forward data from MEM/WB stage way1
			3'b100: bypassOutA_1 = (idex_reg_type_1 == 3'b001) ? WB_csr_data_0 : wRegData_0;	// Forward data from MEM/WB stage way0
			3'b101: bypassOutA_1 = idex_rdA_0;				// Forward data from way0 to way1 in ID/EX stage
			default: bypassOutA_1 = idex_rdA_1;				// Use original ID/EX value
		endcase
	end
end

//--- Select the correct source for Operand B based on bypass logic ---//

// WAY B 0 //

always @(*) begin
    case (bypassB_0)
		3'b001: bypassOutB_0 = EXMEM_ALUOut_1;			// Forward data from EX/MEM stage way1
		3'b010: bypassOutB_0 = EXMEM_ALUOut_0;			// Forward data from EX/MEM stage way0
		3'b011: bypassOutB_0 = (idex_reg_type_0 == 3'b001) ? WB_csr_data_1 : wRegData_1;	// Forward data from MEM/WB stage way1
		3'b100: bypassOutB_0 = (idex_reg_type_0 == 3'b001) ? WB_csr_data_0 : wRegData_0;	// Forward data from MEM/WB stage way0
		default: bypassOutB_0 = (idex_reg_type_0 == 3'b001) ? csr_data_0 : idex_rdB_0;		// Use original ID/EX value or CSR data
    endcase
end

// WAY B 1 //

always @(*) begin
    case (bypassB_1)
		3'b001: bypassOutB_1 = EXMEM_ALUOut_1;			// Forward data from EX/MEM stage way1
		3'b010: bypassOutB_1 = EXMEM_ALUOut_0;			// Forward data from EX/MEM stage way0
		3'b011: bypassOutB_1 = (idex_reg_type_1 == 3'b001) ? WB_csr_data_1 : wRegData_1;	// Forward data from MEM/WB stage way1
		3'b100: bypassOutB_1 = (idex_reg_type_1 == 3'b001) ? WB_csr_data_0 : wRegData_0;	// Forward data from MEM/WB stage way0
		3'b101: bypassOutB_1 = idex_rdB_0;				// Forward data from way0 to way1 in ID/EX stage
		default: bypassOutB_1 = (idex_reg_type_1 == 3'b001) ? csr_data_1 : idex_rdB_1;		// Use original ID/EX value or CSR data
    endcase
end

endmodule
