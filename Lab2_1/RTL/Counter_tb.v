`timescale 1ns/1ns

module Counter_tb();

reg sys_clk = 0;
reg sys_rst = 1;
wire led_out;

Counter #(.CNT_MAX(25'd4)) dut   //5T = 100ns 
(
    .sys_clk(sys_clk),
    .sys_rst(sys_rst),
    .led_out(led_out)
);

always #10 sys_clk = ~sys_clk;  //level invert

initial begin
    $dumpfile("Counter_tb.vcd");
    $dumpvars(0, Counter_tb);

    
    #100;       //ledout=1
    #100;       //ledout=0

    #1 sys_rst=0; //reset
    #19;
    #1 sys_rst=1;
    #19;

    #100;
    
    $finish;

end

endmodule
