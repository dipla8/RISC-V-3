`ifndef SYNTHESIS
`timescale 10ns/10ns
module test();
top TOP();
integer i;
    initial begin
        $dumpfile("ZSOC.vcd");
        $dumpvars(0,test);
    end
endmodule
`endif
