module fpu_adder(
    input [4:0] op,
    input [1:0] ftm,
    input [31:0] number1,
    input [31:0] number2,
    input [2:0] rm,
    output [31:0] out
    );

    wire s1,s2,cout, s2_eff, sticky, n1_is_zero, n2_is_zero, n1_is_nan;
    wire [22:0] m1,m2,m_small, m_large,m_final;
    wire [7:0] e1,e2,d,expdiff,fexp;
    wire [26:0] fl1, fl2, adder_out, mask;
    wire [25:0] fl2_intermediate;
    reg [31:0] fmin_max_out, fcomp_out1, fcomp_out2, fcomp_out3, fcomp_out;
    reg f_sign;
    reg [4:0] count;
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

    // detect zero operands
    assign n1_is_zero = (e1 == 8'b0) && (m1 == 23'b0);
    assign n2_is_zero = (e2 == 8'b0) && (m2 == 23'b0);

    // detect NaN operand
    assign n1_is_nan = (e1 == 8'hFF) && (m1 != 23'b0);

    // If operation is subtract, flip second sign
    assign s2_eff = (op == `FSUB) ? ~s2 : s2;

    // magnitude compare: decide which operand has larger magnitude (exponent then mantissa)
    wire larger_is_op1;
    assign larger_is_op1 = (e1 > e2) ? 1'b1 :
                           (e1 < e2) ? 1'b0 :
                           (m1 >= m2) ? 1'b1 : 1'b0;

    // absolute exponent difference
    assign expdiff = (larger_is_op1) ? (e1 - e2) : (e2 - e1);
    assign fexp = (larger_is_op1) ? e1 : e2;

    // pick mantissas
    assign m_large = (larger_is_op1) ? m1 : m2;
    assign m_small = (larger_is_op1) ? m2 : m1;

    // sticky bit calculator: check bits shifted out from small operand

    assign mask = (1 << expdiff) - 1;
    assign sticky = (m_small == 0 && ((e2 == 0) || (e1 == 0))) ? 0 : |({1'b1, m_small, 2'b0} & mask);

    //fl1 and fl2 are the numbers that are fed into the adder
    assign fl1 = {1'b1,m_large,3'b0};
    assign fl2_intermediate = {1'b1,m_small,2'b0} >> expdiff;
    assign fl2 = {fl2_intermediate,sticky};

    //always block to calculate final sign
    always @(*) begin
        if(op == `FADD || op == `FSUB)begin
            if (larger_is_op1)
                f_sign = s1;
            else
                f_sign = s2_eff;
        end
    end

    //adder
    assign {cout,adder_out} = (s1==s2_eff) ? fl1+fl2 : fl1-fl2;

    //normalisation after addition/substraction
    always @(*) begin
        if(op == `FADD || op == `FSUB)begin
            if (s1==s2_eff) begin
                if (cout && !n1_is_zero && !n2_is_zero) begin
                    exp4 = fexp + 1;
                    out4 = adder_out >> 1;
                end
                else begin
                    exp4 = fexp;
                    out4 = adder_out;
                end
            end
            else begin

                if (adder_out == 27'b0) begin
                    exp4 = 0;
                    out4 = 27'b0;
                    f_sign = 1'b0; // +0 for exact zero
                end
                else begin
                    casex (adder_out)
                        27'b1??????????????????????????: count = 0;
                        27'b01?????????????????????????: count = 1;
                        27'b001????????????????????????: count = 2;
                        27'b0001???????????????????????: count = 3;
                        27'b00001??????????????????????: count = 4;
                        27'b000001?????????????????????: count = 5;
                        27'b0000001????????????????????: count = 6;
                        27'b00000001???????????????????: count = 7;
                        27'b000000001??????????????????: count = 8;
                        27'b0000000001?????????????????: count = 9;
                        27'b00000000001????????????????: count = 10;
                        27'b000000000001???????????????: count = 11;
                        27'b0000000000001??????????????: count = 12;
                        27'b00000000000001?????????????: count = 13;
                        27'b000000000000001????????????: count = 14;
                        27'b0000000000000001???????????: count = 15;
                        27'b00000000000000001??????????: count = 16;
                        27'b000000000000000001?????????: count = 17;
                        27'b0000000000000000001????????: count = 18;
                        27'b00000000000000000001???????: count = 19;
                        27'b000000000000000000001??????: count = 20;
                        27'b0000000000000000000001?????: count = 21;
                        27'b00000000000000000000001????: count = 22;
                        27'b000000000000000000000001???: count = 23;
                        27'b0000000000000000000000001??: count = 24;
                        27'b00000000000000000000000001?: count = 25;
                        27'b000000000000000000000000001: count = 26;
                        default:                         count = 0; // adder_out == 0
                    endcase
                    exp4 = fexp - count;
                    out4 = adder_out << count;
                end
            end
        end
        else if (op == `FMIN || op == `FMAX) begin
            fmin_max_out <=   (n1_is_nan) ? number2 :
                                    (n2_is_zero && n1_is_zero) ? {s1 & s2, 31'b0} : // handle -0 and +0
                                    (s1 != s2) ? (s1 ?  ((op == `FMIN) ? number1 : number2) : 
                                                        ((op == `FMIN) ? number2 : number1)) : //one is negative
                                    ((e1 > e2) || ((e1 == e2) && (m1 > m2))) ? ((s1 == 1'b0) ?  ((op == `FMIN) ? number2 : number1) :   // positive numbers
                                                                                                ((op == `FMIN) ? number1 : number2)) :
                                                                                ((s1 == 1'b0) ? ((op == `FMIN) ? number1 : number2) :
                                                                                                ((op == `FMIN) ? number2 : number1));
        end
        else if (op == `FEQ) begin
            fcomp_out1 <=  (n1_is_nan) ? 32'b0 :
                                (n1_is_zero && n2_is_zero) ? 32'b1 : // handle -0 and +0
                                (number1 == number2) ? 32'b1 : 32'b0;
        end
        else if (op == `FLT) begin
            fcomp_out2 <= (n1_is_nan) ? 32'b0 :
                        (n1_is_zero && n2_is_zero) ? 32'b0 : // handle -0 and +0
                        (s1 != s2) ? (s1 ? 32'b1 : 32'b0) :   // different signs: negative < positive
                        ((e1 > e2) || ((e1 == e2) && (m1 > m2))) ? ((s1 == 1'b0) ? 32'b0 : 32'b1) :   // same sign: compare magnitudes
                                                                   ((s1 == 1'b0) ? 32'b1 : 32'b1);
        end
        else if (op == `FLE) begin
            fcomp_out3 <= (n1_is_nan) ? 32'b0 :
                        (n1_is_zero && n2_is_zero) ? 32'b1 : // handle -0 and +0
                        (number1 == number2) ? 32'b1 :
                        (s1 != s2) ? (s1 ? 32'b1 : 32'b0) :
                        ((e1 > e2) || ((e1 == e2) && (m1 > m2))) ? ((s1 == 1'b0) ? 32'b0 : 32'b1) :
                                                                   ((s1 == 1'b0) ? 32'b1 : 32'b0);
        end
    end

    // round to nearest
    wire round_condition;
    assign round_condition = out4[1] && (out4[2] || out4[0]);
    assign m_final = round_condition ? (out4[25:3] + 23'd1) : out4[25:3];

    //handle mantissa overflow from rounding
    wire mantissa_overflow;
    assign mantissa_overflow = (m_final == 23'd0) && round_condition && (out4[25:3] == 23'h7FFFFF);

    // final number to be output
    wire [7:0] exp4_post;
    assign exp4_post = mantissa_overflow ? (exp4 + 1) : exp4;

    //final number to be output
    assign out = (op == `FADD || op == `FSUB) ? {f_sign, exp4_post, m_final} :
                 (op == `FMIN || op == `FMAX) ? fmin_max_out:
                 (op == `FEQ) ? fcomp_out1 : (op == `FLT) ? fcomp_out2 : (op == `FLE) ? fcomp_out3:
                 32'b0;
    
endmodule
