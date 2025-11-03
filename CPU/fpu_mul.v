module fpu_mul( 
    input op,
    input [31:0] number1,
    input [31:0] number2,
    output [31:0] out
    );

    wire s1,s2,s_final,cout;
    wire last,guard,sticky;
    wire [22:0] m1,m2;
    wire [23:0] fl1,fl2, out_rnd;
    wire [47:0] mul_out, out_nrml, op_out;
    wire [7:0] e1,e2, e_tmp, e_nrml;

    //decompose numbers
    assign s1 = number1[31];
    assign s2 = number2[31];
    assign m1 = number1[22:0];
    assign m2 = number2[22:0];
    assign e1 = number1[30:23];
    assign e2 = number2[30:23];

    assign s_final = (s1==s2) ? 1'b0 : 1'b1;
    assign e_tmp = (op == 1'b0) ? e1+e2-8'b01111111 : e1-e2+8'b01111111;

    assign fl1 = {1'b1,m1};
    assign fl2 = {1'b1,m2};

    //multiplication or division
    assign op_out = (op==1'b0) ? fl1*fl2 : fl1/fl2;

    //normalisation
    assign out_nrml = (op_out[47] && (op== 1'b0)) ? op_out>>1 :
                      (~op_out[47]&&(op==1'b1)) ? op_out<<1: op_out;
    assign e_nrml = (op_out[47]&&(op==1'b0)) ? e_tmp+1 : 
                    (~op_out[47]&&(op==1'b1))? e_tmp-1 : e_tmp;

    assign last = out_nrml[24];
    assign guard = out_nrml[23];
    assign sticky = |out_nrml[22:0];

    assign out_rnd = (guard &&(sticky||last)) ? out_nrml[47:24] + 1 : out_nrml[47:24];

    assign out = {s_final,e_nrml,out_rnd[22:0]};
endmodule
