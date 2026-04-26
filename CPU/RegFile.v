`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif


// Register File. Read ports: address raA, data rdA, renA
//                            address raB, data rdB, renB
//                Write port: address wa, data wd, enable wen.
module RegFile (input  clock, reset,

				// Read ports for instructions
				input	[4:0] 	raA_0, raA_1,
				input	[4:0] 	raB_0, raB_1,
				input			floatingID_0, floatingID_1,
				
				// Write ports for instructions
				input	[4:0]	wa_0, wa_1,
				input			wen_0, wen_1,
				input 	[31:0] 	wd_0, wd_1,
				input			floatingWB_0, floatingWB_1,
				
				// Outputs for instructions
				output	[31:0] 	rdA_0, rdA_1,
				output	[31:0] 	rdB_0, rdB_1
				);

/****** SIGNALS ******/
integer i;
reg [31:0] data[63:0];

/****** LOGIC ******/

// The register file is written at the positive edge. Make sure that bypasssing is enabled. 
always @(posedge clock or negedge reset)
begin
	if (reset == 1'b0) begin
		for (i = 0; i < 32; i = i+1)
			data[i] <= 0;
            data[2] <= 256;
    end
	else begin
		// Writeback data sequencially keeping the priority for instruction 1 if wa_0 == wa_1
        if (wen_0 == 1'b1 && wa_0 != 5'b0) begin
            if (floatingWB_0) data[wa_0 + 32] <= wd_0;
            else              data[wa_0]      <= wd_0;
        end

        if (wen_1 == 1'b1 && wa_1 != 5'b0) begin
            if (floatingWB_1) data[wa_1 + 32] <= wd_1;
            else              data[wa_1]      <= wd_1;
        end	
	end
    
end

// Bypassing is implemented by checking if the current instruction is writing to the same
// register as the one being read, and if so, we output the data being written instead of
// the data in the register file. We also need to check if the write is happening to a floating
// point register or an integer register, and if the read is happening from a floating point
// register or an integer register, to determine if we need to access the upper half of the
// data array (for floating point registers) or the lower half (for integer registers).

// Output A for instruction 0
assign rdA_0 = (wen_1 && wa_1 == raA_0 && wa_1 != 5'b0 && floatingWB_1 == floatingID_0) ? wd_1 :
               (wen_0 && wa_0 == raA_0 && wa_0 != 5'b0 && floatingWB_0 == floatingID_0) ? wd_0 :
               (floatingID_0 ? data[raA_0 + 32] : data[raA_0]);

// Output B for instruction 0
assign rdB_0 = (wen_1 && wa_1 == raB_0 && wa_1 != 5'b0 && floatingWB_1 == floatingID_0) ? wd_1 :
               (wen_0 && wa_0 == raB_0 && wa_0 != 5'b0 && floatingWB_0 == floatingID_0) ? wd_0 :
               (floatingID_0 ? data[raB_0 + 32] : data[raB_0]);

// Output A for instruction 1
assign rdA_1 = (wen_1 && wa_1 == raA_1 && wa_1 != 5'b0 && floatingWB_1 == floatingID_1) ? wd_1 :
               (wen_0 && wa_0 == raA_1 && wa_0 != 5'b0 && floatingWB_0 == floatingID_1) ? wd_0 :
               (floatingID_1 ? data[raA_1 + 32] : data[raA_1]);

// Output B for instruction 1
assign rdB_1 = (wen_1 && wa_1 == raB_1 && wa_1 != 5'b0 && floatingWB_1 == floatingID_1) ? wd_1 :
               (wen_0 && wa_0 == raB_1 && wa_0 != 5'b0 && floatingWB_0 == floatingID_1) ? wd_0 :
               (floatingID_1 ? data[raB_1 + 32] : data[raB_1]);

endmodule
