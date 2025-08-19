`ifndef RV_CONSTANTS
`define RV_CONSTANTS

/********* Timing Constants ********/
/***********************************/
`define clock_period 20
`define clk_to_q_min 0.1
`define clk_to_q_max 0.2
`define setup 0.2
`define hold  0.1
/***********************************/
`define alu_delay	1.5
`define mux2_delay	0.2
`define mux4_delay	0.3
`define mux8_delay  0.4
`define nor32_delay 0.3
/***********************************/
`define mem_data_delay 1.5
`define mem_addr_delay 0.5
`define rf_data_delay  0.7
`define rf_addr_delay  0.5

/********* ALU Operations *********/
`define ADD 5'b00000
`define SUB 5'b00001
`define XOR 5'b00010
`define OR 5'b00011
`define AND 5'b00100
`define SLL 5'b00101
`define SRL 5'b00110
`define SRA 5'b00111
`define SLT 5'b01000
`define SLTU 5'b01001
`define SUBU 5'b01010
`define LUI 5'b01011
`define AUIPC 5'b01100
`define CLEAR 5'b01101 
`define MUL 5'b01110
`define MULH 5'b01111
`define MULHSU 5'b10000
`define MULHU 5'b10001
`define DIV 5'b10010
`define DIVU 5'b10011
`define REM 5'b10100
`define REMU 5'b10101
`define FADD 1'b1

/********* Opcode Formats *********/

`define R_FORMAT  7'b0110011
`define I_COMP_FORMAT 7'b0010011
`define I_LOAD_FORMAT 7'b0000011
`define I_JALR_FORMAT 7'b1100111
`define I_ENV_FORMAT 7'b1110011 //SYSTEM INSTRUCTIONS
`define S_FORMAT 7'b0100011
`define B_FORMAT 7'b1100011
`define J_FORMAT 7'b1101111
`define U_FORMAT_LUI 7'b0110111   // U-format
`define U_FORMAT_AUIPC 7'b0010111 // U-format
`define F_FORMAT 7'b1010011
`define F_LOAD_FORMAT 7'b0000111
`define F_SAVE_FORMAT 7'b0100111

/************ Funct3 *************/
/*********** R-format ************/
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_XOR 3'b100
`define FUNCT3_OR 3'b110
`define FUNCT3_AND 3'b111
`define FUNCT3_SLL 3'b001
`define FUNCT3_SRL 3'b101
`define FUNCT3_SLT 3'b010
`define FUNCT3_SLTU 3'b011
`define FUNCT3_MUL 3'b000
`define FUNCT3_MULH 3'b001
`define FUNCT3_MULHSU 3'b010
`define FUNCT3_MULHU 3'b011
`define FUNCT3_DIV 3'b100
`define FUNCT3_DIVU 3'b101
`define FUNCT3_REM 3'b110
`define FUNCT3_REMU 3'b111

/********* I-COMP-format *********/
`define FUNCT3_ADDI 3'b000
`define FUNCT3_XORI 3'b100
`define FUNCT3_ORI 3'b110
`define FUNCT3_ANDI 3'b111
`define FUNCT3_SLLI 3'b001
`define FUNCT3_SRLI 3'b101
`define FUNCT3_SLTI 3'b010
`define FUNCT3_SLTIU 3'b011
/********* I-LOAD-format *********/
`define FUNCT3_LB 3'b000
`define FUNCT3_LH 3'b001
`define FUNCT3_LW 3'b010
`define FUNCT3_LBU 3'b100
`define FUNCT3_LHU 3'b101
/*********** S-format ************/
`define FUNCT3_SB 3'b000
`define FUNCT3_SH 3'b001
`define FUNCT3_SW 3'b010
/*********** B-format ************/
`define FUNCT3_BEQ 3'b000
`define FUNCT3_BNE 3'b001
`define FUNCT3_BLT 3'b100
`define FUNCT3_BGE 3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111

/*********** CSR Instructions ************/
`define FUNCT3_CSRRW 3'b001  // CSR Read and Write
`define FUNCT3_CSRRS 3'b010  // CSR Read and Set
`define FUNCT3_CSRRC 3'b011  // CSR Read and Clear
`define FUNCT3_CSRRWI 3'b101 // CSR Read and Write Immediate
`define FUNCT3_CSRRSI 3'b110 // CSR Read and Set Immediate
`define FUNCT3_CSRRCI 3'b111 // CSR Read and Clear Immediate


/******* Funct7, R-format ********/
`define FUNCT7_ADD 7'h00
`define FUNCT7_SUB 7'b0100000
`define FUNCT7_MUL 7'b0000001

/********* ALUcntrl Codes ********/
`define ALU_R 4'b0000
`define ALU_LOAD_STORE 4'b0001
`define ALU_BRANCH 4'b0010
`define ALU_LUI    4'b0011
`define ALU_AUIPC  4'b0100 
`define ALU_I_COMP 4'b0101
`define ALU_J      4'b0110
`define ALU_CSR      4'b0111
`define FPU	4'b1000

`define NOP 32'b0000_0000_0000_0000_0000_0000_0000_0000

`define BEQ_CODE 2'b00
`define BNE_CODE 2'b01
`define BLT_CODE 2'b10
`define BGE_CODE 2'b11

`endif
