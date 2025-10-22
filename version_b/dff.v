module dff(clk, D, Q, Qbar);
    input clk, D;
    output reg Q;
    output reg Qbar;

    always@(posedge clk) begin
        Q <= D;
        Qbar <= ~D;
    end
    
endmodule