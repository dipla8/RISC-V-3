//100MHz / 4Hz = 25*10^6 cycles, 12.5*10^6 positive edges in total
module slowclock(input clkin, input reset, output reg clkout);
    reg [25:0] count; //2^26-1 wste na xwraei to 12.5*10^6

    always@(posedge clkin) begin
        if(reset)begin
		count = 0;
		clkout = 0;
	end
	count <= count + 1;
        if(count >= 4) begin //valame >= gia na apofygoume tyxon bugs
            count <= 0;
            clkout <= ~clkout; //to neo clock exei periodo 0.25sec
        end
    end

endmodule
