module debouncer2(btn, clkin, reset, pulseout);
    input btn, clkin, reset;
    output pulseout;
    wire clkout;
    wire Q1, Q1bar, Q2, Q2bar;

    slowclock clk0(clkin,reset, clkout);
    dff DFF1(clkout, btn, Q1, Q1bar);
    dff DFF2(clkout, Q1, Q2, Q2bar);

    assign pulseout = Q1 & Q2bar;

endmodule
