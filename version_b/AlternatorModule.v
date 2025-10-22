module Alternator(
		input clk, reset,
		output reg [3:0] an
		);
reg [3:0] state;
always@(clk)begin
	if(reset)begin
		state <= 4'b0000;
		an <= 4'b0000;
	end
	else begin
	    case(state)
		4'b1110: begin an[3] <= 0; state <= state+1;end
		4'b1010: begin an[2] <= 0; state <= state+1;end
		4'b0110: begin an[1] <= 0; state <= state+1;end
		4'b0010: begin an[0] <= 0; state <= state+1;end
		4'b1111: begin an <= 4'b1111; state <= 4'b0000;end
		default: begin an <= 4'b1111; state <=state+1;end
	      endcase
	end
end
endmodule
