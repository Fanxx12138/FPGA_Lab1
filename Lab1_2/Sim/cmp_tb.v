`timescale 1ns / 1ns

module cmp_tb();

reg B2;
reg B3;
wire led1;
wire led2;
wire led3;

cmp dut(
    .key1(B2),
    .key2(B3),
    .led1(led1),
    .led2(led2),
    .led3(led3)
);

initial begin
    $dumpfile("cmp_tb.vcd");
    $dumpvars(0,cmp_tb);

    B2 = 1; B3 = 1;
    #20;
    B2 = 1; B3 = 0; //A0 B1 lt led1
    #20;
    B2 = 0; B3 = 0; //A1 B1 eq led2
    #20;
    B2 = 0; B3 = 1; //A1 B0 gt led3
    #20;
    $finish;

end


endmodule