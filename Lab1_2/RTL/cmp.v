`timescale 1ns / 1ns

module cmp(
    input key1,  //to control A
    input key2,  //.. B
    output led1, //.. lt
    output led2, //.. eq
    output led3  //.. gt
);

wire A,B,lt,gt,eq;

assign A = ~key1;
assign B = ~key2;
assign led1 = ~lt;
assign led2 = ~eq;
assign led3 = ~gt;

assign lt = ~A & B;
assign gt = A & ~B;
assign eq = ~(A ^ B);

endmodule