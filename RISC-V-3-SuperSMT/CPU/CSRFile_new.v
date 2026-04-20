`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif

// Control and Status Register File
module CSRFile (
    input clock,
    input reset,
    input [11:0] csrAddr,
    input [11:0] csrWAddr,
    input ren,
    input wen,
    input [31:0] wd,
    output reg [31:0] rd,
    input write_pc,
    input [1:0] IFID_hartid,
    input [1:0] IDEX_hartid,
    input [1:0] EXMEM_hartid,
    input [1:0] MEMWB_hartid,

    // CLIC signals
    input [31:0] PC,
    //input [31:0] IDEX_PC,
    input [31:0] PC_ID,
    input timer_interrupt,
    input software_interrupt,
    input external_interrupt,
    input syscall,
    input [4:0] fpflags,
    output reg int_taken,
    output reg trap_in_ID,
    output reg flushPipeline,
    output reg [31:0] trap_vector
);

parameter FLUSH_COUNT = 4'd13;
/****** SIGNALS ******/
integer i;

reg [31:0] mstatus [3:0];  // Machine status register address 0x300
reg [31:0] mstatush [3:0]; // Machine status register address 0x310
reg [31:0] misa [3:0];     // Machine ISA register address 0x301
reg [31:0] mie [3:0];      // Machine interrupt enable register address 0x304
reg [31:0] mtvec [3:0];    // Machine trap vector base address register address 0x305
reg [31:0] mscratch [3:0]; // Machine scratch register address 0x340
reg [31:0] mepc [3:0];     // Machine exception program counter register address 0x341
reg [31:0] mcause [3:0];   // Machine cause register address 0x342
reg [31:0] mtval [3:0];    // Machine trap value register address 0x343
wire [31:0] mip;           // Machine interrupt pending register address 0x344

reg [7:0] fcsr [3:0]; // FP CSR

assign mip = {16'b0,2'b0,IFID_hartid,external_interrupt,3'b0,timer_interrupt,3'b0,software_interrupt,3'b0};

reg [2:0] enableInterrupts;
reg [3:0] pipeline_flush_count;

always @(posedge clock or negedge reset)
begin
    if(reset == 1'b0)
    begin
        // Arrays must be reset using a loop
        for (i = 0; i < 4; i = i + 1) begin
            mstatus[i]  <= 32'b0;
            mstatush[i] <= 32'b0;
            misa[i]     <= 32'h40000100;
            mie[i]      <= 32'b0;
            mtvec[i]    <= 32'b0;
            mscratch[i] <= 32'b0;
            mepc[i]     <= 32'b0;
            mcause[i]   <= 32'b0;
            mtval[i]    <= 32'b0;
            fcsr[i]     <= 8'b0;
        end
        rd <= 32'b0;
        int_taken <= 1'b0;
        trap_vector <= 32'b0;
        enableInterrupts <= 3'b111;
        flushPipeline <= 1'b0;
        pipeline_flush_count <= FLUSH_COUNT;
    end
    else
    begin
        // Read/Write section
        if(wen == 1'b1)
        begin
            case(csrWAddr)
                12'h300: mstatus[MEMWB_hartid]  <= wd;
                12'h304: mie[MEMWB_hartid]      <= wd;
                12'h305: mtvec[MEMWB_hartid]    <= {wd[31:2], 2'b0};
                12'h301: mstatush[MEMWB_hartid] <= wd;
                12'h340: mscratch[MEMWB_hartid] <= wd;
                12'h341: mepc[MEMWB_hartid]     <= wd;
                12'h342: mcause[MEMWB_hartid]   <= wd;
                12'h343: mtval[MEMWB_hartid]    <= wd;
            endcase
        end
        
        if(csrAddr == csrWAddr && wen)
        begin
            rd <= wd; // Forwarding
        end
        else begin
            if(write_pc) begin
                case(csrAddr)
                    12'h300: rd <= mstatus[IFID_hartid];
                    12'h301: rd <= misa[IFID_hartid];
                    12'h304: rd <= mie[IFID_hartid];
                    12'h305: rd <= mtvec[IFID_hartid];
                    12'h310: rd <= mstatush[IFID_hartid]; // Usually 0x310 or 0x311
                    12'h340: rd <= mscratch[IFID_hartid];
                    12'h341: rd <= mepc[IFID_hartid];
                    12'h342: rd <= mcause[IFID_hartid];
                    12'h343: rd <= mtval[IFID_hartid];
                    12'h344: rd <= mip; // mip is a scalar wire here
		    12'hF14: rd <= MEMWB_hartid;
                    default: rd <= 32'b0;
                endcase
            end
        end

        // Interrupt handling section
        if(enableInterrupts <= 3'b110)
        begin
            enableInterrupts <= enableInterrupts + 1;
            if(enableInterrupts == 3'b110)
            begin
                // Note the array indexing order: register[hartid][bit]
                mstatus[IDEX_hartid][3] <= mstatus[IDEX_hartid][7];
            end
        end

        if(flushPipeline == 1'b1)
        begin
            if(write_pc == 1'b1)
                pipeline_flush_count <= pipeline_flush_count + 1;
            if(pipeline_flush_count == FLUSH_COUNT)
            begin
                flushPipeline <= 1'b0;
                //mepc[IDEX_hartid] <= IDEX_PC;
                mepc[IDEX_hartid] <= PC_ID;
                
		int_taken <= 1'b1;
            end
        end
        else if(write_pc == 1'b1)
        begin
            int_taken <= 1'b0;
            trap_in_ID <= 1'b0;

            if(syscall == 1'b1) begin
                // ecall instruction
                if(csrAddr == 0) begin
                //mepc[IDEX_hartid] <= IDEX_PC;
                    mepc[IDEX_hartid] <= PC_ID;
                    trap_in_ID <= 1'b1;
                    trap_vector <= {mtvec[IDEX_hartid][31:2], 2'b0};
                    mcause[IDEX_hartid] <= {1'b1, 31'd11};
                    mstatus[IDEX_hartid][7] <= mstatus[IDEX_hartid][3];
                    mstatus[IDEX_hartid][3] <= 1'b0;
                end
                // ebreak instruction
                else if(csrAddr == 1) begin
                //    mepc[IDEX_hartid] <= IDEX_PC;
                    mepc[IDEX_hartid] <= PC_ID;
                    trap_in_ID <= 1'b1;
                    trap_vector <= {mtvec[IDEX_hartid][31:2], 2'b0};
                    mcause[IDEX_hartid] <= {1'b1, 31'd3};
                    mstatus[IDEX_hartid][7] <= mstatus[IDEX_hartid][3];
                    mstatus[IDEX_hartid][3] <= 1'b0;
                end
                // mret instruction
                else if(csrAddr == 12'h302) begin
                    trap_in_ID <= 1'b1;
                    trap_vector <= mepc[IDEX_hartid];
                    enableInterrupts <= 0;
                end
            end
            // Check MIE bit for the specific hart
            else if(mstatus[IDEX_hartid][3] == 1'b1) begin
                // external interrupt
                if(external_interrupt & mie[IDEX_hartid][11] & mip[11]) begin
                    trap_vector <= {mtvec[IDEX_hartid][31:2], 2'b0};
                    mcause[IDEX_hartid] <= {1'b1, 31'd11};
                    mstatus[IDEX_hartid][7] <= mstatus[IDEX_hartid][3];
                    mstatus[IDEX_hartid][3] <= 1'b0;
                    flushPipeline <= 1'b1;
                    pipeline_flush_count <= 0;
                end
                // timer interrupt
                else if(timer_interrupt & mie[IDEX_hartid][7] & mip[7]) begin
                    trap_vector <= {mtvec[IDEX_hartid][31:2], 2'b0};
                    mcause[IDEX_hartid] <= {1'b1, 31'd7};
                    mstatus[IDEX_hartid][7] <= mstatus[IDEX_hartid][3];
                    mstatus[IDEX_hartid][3] <= 1'b0;
                    flushPipeline <= 1'b1;
                    pipeline_flush_count <= 0;
                end
                // software interrupt
                else if(software_interrupt & mie[IDEX_hartid][3] & mip[3]) begin
                    trap_vector <= {mtvec[IDEX_hartid][31:2], 2'b0};
                    mcause[IDEX_hartid] <= {1'b1, 31'd3};
                    mstatus[IDEX_hartid][7] <= mstatus[IDEX_hartid][3];
                    mstatus[IDEX_hartid][3] <= 1'b0;
                    flushPipeline <= 1'b1;
                    pipeline_flush_count <= 0;
                end
            end
        end
    end
end

endmodule
