`timescale 1ns/1ns
module Running_Light_tb();

reg clk=0;
reg B3=1;
wire led0,led1,led2,led3;

Running_Light #(.CNT_MAX(25'd1)) dut //40ns
(
    .sys_clk(clk),
    .sys_rst_n(B3),
    .led0(led0),
    .led1(led1),
    .led2(led2),
    .led3(led3)
);

always #10 clk = ~clk;    //T=20ns

initial begin
    $dumpfile("Running_Light_tb.vcd");
    $dumpvars(0, Running_Light_tb);

    #40;  //led1
    #40;  //led2
    #5;   B3=0;
    #1;   B3=1;
    #39;  //led1
    #40;  //led2
    #40;  //led3
    #40;  //led0

    #10 $finish;
end

endmodule