`timescale 1ns/1ns

module Counter#(parameter [0:24] CNT_MAX = 25'd24999999)
(
    input sys_clk,      //Clock T
    input sys_rst,      //release 1 press 0  (release to reset)
    output reg led_out  //led_out=0 , turn_on
);
reg state = 1'b1;
reg  [0:24] cnt = 25'd0;
initial  led_out = 0;

always @(posedge sys_clk) state <= sys_rst; //to recode the last sys_rst

always @(posedge sys_clk ) begin

        if(state==0 && sys_rst==1) begin    
            led_out <= 1'b0;
            cnt <= 25'b0;
        end

        else if (cnt==CNT_MAX) begin
            led_out <= ~led_out;
            cnt <= 25'b0;
        end

        else begin
            cnt <= cnt+25'b1;
        end
end

endmodule
