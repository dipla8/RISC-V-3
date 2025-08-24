`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif

/************** control for ALU control in EX pipe stage  *************/
module control_ex(			
					output reg [4:0] ALUOp,
					output reg [1:0] FPUOp, // to be extended
					output reg csr_immidiate,
					input [3:0] EXcntrl,
					input [2:0] funct3,
					input [6:0] funct7);

always @(EXcntrl or funct3 or funct7)
begin
	csr_immidiate = 0;
	FPUOp = 0;
	case (EXcntrl)
		`ALU_R: begin
			case ({funct7, funct3})
				{`FUNCT7_ADD,`FUNCT3_ADD_SUB}:	ALUOp = `ADD;
				{`FUNCT7_SUB,`FUNCT3_ADD_SUB}: ALUOp = `SUB;
				{`FUNCT7_ADD,`FUNCT3_XOR}: ALUOp = `XOR;
				{`FUNCT7_ADD,`FUNCT3_OR}: ALUOp = `OR;
				{`FUNCT7_ADD,`FUNCT3_AND}: ALUOp = `AND;
				{`FUNCT7_ADD,`FUNCT3_SLL}: ALUOp = `SLL;
				{`FUNCT7_ADD,`FUNCT3_SRL}: ALUOp = `SRL;
				{`FUNCT7_SUB,`FUNCT3_SRL}: ALUOp = `SRA;
				{`FUNCT7_ADD,`FUNCT3_SLT}: ALUOp = `SLT;
				{`FUNCT7_ADD,`FUNCT3_SLTU}: ALUOp = `SLTU;
				{`FUNCT7_MUL, `FUNCT3_MUL}: ALUOp = `MUL;
				{`FUNCT7_MUL, `FUNCT3_MULH}: ALUOp = `MULH;
				{`FUNCT7_MUL, `FUNCT3_MULHSU}: ALUOp = `MULHSU;
				{`FUNCT7_MUL, `FUNCT3_MULHU}: ALUOp = `MULHU;
				{`FUNCT7_MUL, `FUNCT3_DIV}: ALUOp = `DIV;
				{`FUNCT7_MUL, `FUNCT3_DIVU}: ALUOp = `DIVU;
				{`FUNCT7_MUL, `FUNCT3_REM}: ALUOp = `REM;
				{`FUNCT7_MUL, `FUNCT3_REMU}: ALUOp = `REMU;
				default: ALUOp = `ADD;
			endcase
		end
		`FPU: begin
			ALUOp = `ADD;
			FPUOp = `FADD;
		end
		`ALU_LOAD_STORE: begin
			ALUOp  = `ADD;
		end
		`ALU_BRANCH: begin
			case (funct3)
				`FUNCT3_BEQ, `FUNCT3_BNE, `FUNCT3_BLT, `FUNCT3_BGE:	ALUOp = `SUB;
				`FUNCT3_BLTU, `FUNCT3_BGEU:							ALUOp = `SUBU;
				default:											ALUOp = `SUB;
			endcase
		end
		`ALU_LUI: begin
			ALUOp = `LUI;
		end
		`ALU_AUIPC: begin
			ALUOp = `AUIPC;
		end
		`ALU_I_COMP: begin
			case (funct3)
				`FUNCT3_ADDI:	ALUOp = `ADD;
				`FUNCT3_XORI:	ALUOp = `XOR;
				`FUNCT3_ORI:	ALUOp = `OR;
				`FUNCT3_ANDI:	ALUOp = `AND;
				`FUNCT3_SLLI:	ALUOp = `SLL;
				`FUNCT3_SRLI:	ALUOp = (funct7 == `FUNCT7_SUB) ? `SRL : `SRA;
				`FUNCT3_SLTI:	ALUOp = `SLT;
				`FUNCT3_SLTIU:	ALUOp = `SLTU;
				default:		ALUOp = `ADD;
			endcase
		end
		`ALU_J: begin
			ALUOp = `ADD;
		end
		`ALU_CSR:begin
			case (funct3)
				`FUNCT3_CSRRW:
				begin
					csr_immidiate = 0;
					ALUOp = `ADD;
				end
				`FUNCT3_CSRRS:
				begin
					csr_immidiate = 0;
					ALUOp = `OR;
				end
				`FUNCT3_CSRRC:
				begin
					csr_immidiate = 0;
					ALUOp = `CLEAR;
				end
				`FUNCT3_CSRRWI:
				begin
					csr_immidiate = 1;
					ALUOp = `ADD;
				end
				`FUNCT3_CSRRSI:
				begin
					csr_immidiate = 1;
					ALUOp = `OR;
				end
				`FUNCT3_CSRRCI:
				begin
					csr_immidiate = 1;
					ALUOp = `CLEAR;
				end
				default:
				begin
					csr_immidiate = 0;
					ALUOp = `ADD;
				end
			endcase
		end
		default: begin
			ALUOp = `ADD;
		end
	endcase
end
endmodule
