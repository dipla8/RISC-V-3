module messageFSM(
	input clk,
	input reset,
	input button,
	output reg [3:0] a,b,c,d);
always@(clk)begin
	if(reset)begin
		a = 4'b0000;
		b = 4'b0001;
		c = 4'b0010;
		d = 4'b0011;
	end
	else if(button) begin
		if(a == 4'b1111)begin
			a <= 4'b0000;
		end
		else begin
			a <= a+1;
		end
		if(b == 4'b1111)begin
			b <= 4'b0000;
		end
		else begin
			b <= b+1;
		end
		if(c == 4'b1111)begin
			c <= 4'b0000;
		end
		else begin
			c <= c+1;
		end
		if(d == 4'b1111)begin
			d <= 4'b0000;
		end
		else begin
			d <= d+1;
		end
	end
end
endmodule
