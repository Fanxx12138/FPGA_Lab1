`timescale 1ns/1ns

module fadd_tb();

    reg key1;
    reg key2;
    reg key3;
    wire led1;
    wire led2;

    fadd dut(
        .key1(key1),
        .key2(key2),
        .key3(key3),
        .led1(led1),
        .led2(led2)
    );

    initial begin
        $dumpfile("fadd_tb.vcd");
        $dumpvars(0,fadd_tb);
        
        key1=1;key2=1;key3=1;
        #20;
        key1 = 1; key2 = 1; key3 = 0;  //ABCin = 001
        #20;
        key1 = 1; key2 = 0; key3 = 1;  //010
        #20;
        key1 = 1; key2 = 0; key3 = 0;  //011
        #20;
        key1 = 0; key2 = 1; key3 = 1;  //100
        #20;
        key1 = 0; key2 = 1; key3 = 0;  //101
        #20;
        key1 = 0; key2 = 0; key3 = 1;  //110
        #20;
        key1 = 0; key2 = 0; key3 = 0;  //111
        #20;

        $finish;
    end



endmodule