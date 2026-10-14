`timescale 1ns/1ns
module fadd (
    input key1,
    input key2,
    input key3,
    output led1,
    output led2
);

wire A,B,Cin;
wire S,Cout;

assign A = ~key1;
assign B = ~key2;
assign Cin = ~key3;

assign S=A^B^Cin;
assign Cout = (A&B) | (A&Cin) | (B&Cin);

assign led1 = ~S;
assign led2 = ~Cout;

endmodule