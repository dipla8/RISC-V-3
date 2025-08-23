module fpu_adder(number1,number2,out);

    input [31:0] number1,number2;
    output [31:0] out;

    wire s1,s2,cout;
    wire [22:0] m1,m2,m_small, m_large,m_final;
    wire [7:0] e1,e2,d,expdiff,fexp;
    wire [26:0] fl1, fl2, adder_out;
    wire [25:0] fl2_intermediate;
    reg sticky,f_sign,count;
    reg [26:0]out4;
    reg [7:0]exp4;
    integer i;

    //decompose numbers
    assign s1 = number1[31];
    assign s2 = number2[31];
    assign m1 = number1[22:0];
    assign m2 = number2[22:0];
    assign e1 = number1[30:23];
    assign e2 = number2[30:23];

    //exponent comparison
    assign d = e1-e2;
    assign expdiff = (d > 0) ? d : -d;
    assign fexp = (d > 0) ? e1 : e2;

    assign m_small = (d > 0) ? m2 : m1;
    assign m_large = (d > 0) ? m1 : m2;

    //sticky bit calculator
    always @(*) begin
        sticky = 0;
        for (i=0; i < expdiff; i = i+1) begin
            if (m_small[i] == 1'b1)
                sticky = 1;
        end
    end

    //fl1 and fl2 are the numbers that are fed into the adder
    assign fl1 = {1'b1,m_large,3'b0};
    assign fl2_intermediate = {1'b1,m_small,2'b0} >> expdiff;
    assign fl2 = {fl2_intermediate,sticky};


    //////////////////////////////////////////////////

    //always block to calculate final sign
    always @(*) begin

        if ((s1==s2) || (d>0)) 
            f_sign = s1;
        else if (d<0)
            f_sign = s2;
        else begin
            if (m1>m2)
                f_sign = s1;
            else
                f_sign = s2;
        end
    end

    //adder
    assign {cout,adder_out} = (s1==s2) ? fl1+fl2 : fl1-fl2;

    ///////////////////////////////////////////////////////////////////

    //normalisation after addition/substraction
    always @(*) begin
        if (s1==s2) begin
            if (cout) begin
                exp4 = fexp + 1;
                out4 = adder_out >> 1;
            end
            else begin
                exp4 = fexp;
                out4 = adder_out;
            end
        end
        else begin
            for (i=31; (i>=0)&&(adder_out[i]==0);i = i-1) begin
            end
            count = 31-i;
            exp4 = fexp - count;
            out4 = adder_out << count;
        end
    end

    //rounding logic
    assign m_final = (out4[1]&&(out4[2]||out4[0])) ? out4[25:2] + 1 : out4[25:2];

    //final number to be output
    assign out = {f_sign,exp4,m_final};
    
endmodule