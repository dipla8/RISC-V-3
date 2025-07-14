`ifndef SYNTHESIS
`timescale 10ns/10ns
module test();
top top1();
    initial begin
        $dumpfile("ZSOC.vcd");
        $dumpvars(0,test);
    end
endmodule
`endif
