`include "constants.vh"
module LEDdecoder(
	input [3:0] symbol,
	output reg [7:0] LED
);
    always@(symbol) begin
        case(symbol)
            4'b0000: LED = `ONE;
            4'b0001: LED = `TWO;
            4'b0010: LED = `THREE;
            4'b0011: LED = `FOUR;
            4'b0100: LED = `FIVE;
            4'b0101: LED = `SIX;
            4'b0110: LED = `SEVEN;
            4'b0111: LED = `EIGHT;
            4'b1000: LED = `NINE;
            4'b1001: LED = `ALPHA;
            4'b1010: LED = `BETA;
            4'b1011: LED = `CHARLIE;
            4'b1100: LED = `DELTA;
            4'b1101: LED = `ECHO;
            4'b1110: LED = `CHARLIE;
            4'b1111: LED = `FOXTROT;
	    default: LED = `EIGHT;
        endcase
	end
endmodule
