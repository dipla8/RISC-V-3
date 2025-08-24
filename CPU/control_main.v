`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif


/************** Main control in ID pipe stage  *************/
module control_main(output reg RegDst,
					output reg Branch,
					output reg MemRead,
					output reg MemWrite,
					output reg MemToReg,
					output reg ALUSrc,
					output reg RegWrite,
					output reg Jump,
					output reg JumpJALR,
					output reg inA_is_PC,
					output reg [1:0] reg_type,
					output reg [3:0] EXcntrl,
					input [6:0] opcode);

always @(*)
begin
	reg_type = 0; // sets registers to x registers
	case (opcode)
		`R_FORMAT: begin 
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_R;
		end
		`I_COMP_FORMAT: begin
			RegDst 		= 1'b1;
			MemRead 	= 1'b0;
			MemWrite 	= 1'b0;
			MemToReg 	= 1'b0;
			ALUSrc 		= 1'b1;
			RegWrite 	= 1'b1;
			Branch 		= 1'b0;
			Jump 		= 0;
			JumpJALR 	= 0;
			inA_is_PC 	= 1'b0;
			EXcntrl 	= `ALU_I_COMP;
		end
		`I_LOAD_FORMAT: begin 
			RegDst		= 1'b1;
			MemRead		= 1'b1;
			MemWrite	= 1'b0;
			MemToReg	= 1'b1;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_LOAD_STORE;
		end
		`I_ENV_FORMAT: 	begin
			reg_type 	= 2'b01; // sets registers to CSR registers
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_CSR;
		end

		`I_JALR_FORMAT: begin
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 1;
			inA_is_PC	= 1'b1;
			EXcntrl	= `ALU_J;
		end
		`S_FORMAT: begin 
			RegDst		= 1'b0;
			MemRead		= 1'b0;
			MemWrite	= 1'b1;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b0;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_LOAD_STORE;
		end
		`B_FORMAT: begin 
			RegDst		= 1'b0;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b0;
			Branch		= 1'b1;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_BRANCH;
		end
		`J_FORMAT: begin
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 1;
			JumpJALR	= 0;
			inA_is_PC	= 1'b1;
			EXcntrl	= `ALU_J;
		end
		`U_FORMAT_LUI: begin
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 1'b0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_LUI;
		end
		`U_FORMAT_AUIPC: begin
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 1'b0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b1;
			EXcntrl	= `ALU_AUIPC;
		end
		`F_FORMAT: begin 
			reg_type 	= 2'b10; // FP registers
			RegDst		= 1'b1;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl		= `FPU;
		end
		`F_LOAD_FORMAT: begin 
			reg_type 	= 2'b11; // FP registers
			RegDst		= 1'b1;
			MemRead		= 1'b1;
			MemWrite	= 1'b0;
			MemToReg	= 1'b1;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b1;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_LOAD_STORE;
		end
		`F_SAVE_FORMAT: begin 
			reg_type 	= 2'b11; // FP registers
			RegDst		= 1'b0;
			MemRead		= 1'b0;
			MemWrite	= 1'b1;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b1;
			RegWrite	= 1'b0;
			Branch		= 1'b0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_LOAD_STORE;
		end
		default: begin
			RegDst		= 1'b0;
			MemRead		= 1'b0;
			MemWrite	= 1'b0;
			MemToReg	= 1'b0;
			ALUSrc		= 1'b0;
			RegWrite	= 1'b0;
			Branch		= 0;
			Jump		= 0;
			JumpJALR	= 0;
			inA_is_PC	= 1'b0;
			EXcntrl	= `ALU_R;
		end
	endcase
end // always
endmodule
