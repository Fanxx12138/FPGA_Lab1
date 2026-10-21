`timescale 1ns/1ns
module Running_Light #(parameter CNT_MAX = 25'd24999999)
(
    input sys_clk,
    input sys_rst_n,
    output reg led0,
    output reg led1,
    output reg led2,
    output reg led3
);
reg [24:0] cnt=25'b0;
reg [1:0]  state=2'b1;

initial begin
    led0=0;led1=1;led2=1;led3=1;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        led0<=0;led1<=1;led2<=1;led3<=1;
        state<=1;  //next time:let led1 turn_on
        cnt<=0;
    end
    else if(cnt==CNT_MAX && state==0) begin
        led0<=0;
        led1<=1;led2<=1;led3<=1;
        state<=state+1;
        cnt<=0;
    end
    else if(cnt==CNT_MAX && state==1) begin
        led1<=0;
        led0<=1;led2<=1;led3<=1;
        state<=state+1;
        cnt<=0;
    end
    else if(cnt==CNT_MAX && state==2) begin
        led2<=0;
        led0<=1;led1<=1;led3<=1;
        state<=state+1;
        cnt<=0;
    end
    else if(cnt==CNT_MAX && state==3) begin
        led3<=0;
        led0<=1;led1<=1;led2<=1;
        state<=0;
        cnt<=0;
    end
    else  cnt<=cnt+1;

end

endmodule