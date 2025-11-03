module fpu(input [4:0] FPUOp, input [31:0] number1, input [31:0] number2, output [31:0] out);
wire [31:0] adderout, mulout, conout, sqrtout, sigout;
assign out = FPUOp ==`FADD ? adderout :  FPUOp ==`FSUB ? adderout :  FPUOp ==`FMUL ? mulout :  FPUOp ==`FDIV ? mulout :  FPUOp ==`FSQRT ? sqrtout :  FPUOp ==`FSGNJ ? sigout :  FPUOp ==`FSGNJN ? sigout :  FPUOp ==`FSGNJX ? sigout :  FPUOp ==`FMIN ? adderout :  FPUOp ==`FMAX ? adderout :  FPUOp ==`FCVTWS ? conout :  FPUOp ==`FCVTWUS ? conout :  FPUOp ==`FMVXW ? conout :  FPUOp ==`FEQ ? adderout :  FPUOp ==`FLT ? adderout :  FPUOp ==`FLE ? adderout :  FPUOp ==`FCLASS ? conout :  FPUOp ==`FCVTSW ? conout :  FPUOp ==`FCVTSWU ? conout :  FPUOp ==`FMVWX ? conout : adderout;
// in this way for comparison instructions (floating slt etc.), the output of the adder is subtraction automatically
fpu_adder fpu_adder1(.op(FPUOp), .number1(number1), .number2(number2), .out(adderout));
fpu_mul fpu_mul1(.op(FPUOp != `FDIV), .number1(number1), .number2(number2), .out(mulout));
sign_commands sign_instructions(.op(FPUOp == `FSGNJ ? 2'b00 : FPUOp == `FSGNJN ? 2'b01 : 2'b10), .number1(number1), .number2(number2), .out(sigout));
floating_convert floating_convert1(.FPUOp(FPUOp), .in_num(number1), .out(conout), .overflow(overflow));
fsqrt fsqrt1(.in_num(number1), .out(sqrtout));
endmodule
