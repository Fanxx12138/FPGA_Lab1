`timescale 1ns / 1ps
//=============================================================================
// key_debounce.v  --  按键消抖 + 单次点击脉冲
//
// 机械按键按下和松开时会抖动 5~10 ms。做法照讲义：
//   1) 用计数器连续数 N 个时钟，只有电平一直不变才算真的按下/松开；
//   2) 消抖后的电平再打一拍，检测 1 -> 0 的下降沿，得到"一次点击"。
//
// 时间预算：
//   25 MHz 像素时钟，20 ms 需要 25e6 x 0.02 = 500000 个时钟，
//   所以计数器数到 500000-1 即可（19 位计数器）。
//   抖动最长 10 ms < 20 ms，按键一直按住时也只产生一个脉冲。
//
// 输出 key_flag 只保持一个时钟周期，因此无论按多久都只切换一次画面。
//=============================================================================
module key_debounce(
    input  wire clk,        // 25 MHz
    input  wire rst_n,      // 低电平有效复位
    input  wire key_in,     // 低电平有效按键
    output wire key_flag    // 一次点击输出一个时钟周期的正脉冲
);

    // 20 ms @ 25 MHz
    parameter [18:0] CNT_MAX = 19'd499_999;

    reg [18:0] cnt;         // 电平不变的计时
    reg        key_reg;     // 消抖后的电平，1 = 松开
    reg        key_reg_d;   // 上一拍的 key_reg

    //------------------------------------------------------- 20 ms 消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 19'd0;
            key_reg <= 1'b1;            // 复位时按"松开"处理
        end
        else if (key_in != key_reg) begin
            if (cnt == CNT_MAX) begin   // 连续 20 ms 都不同，才认可新电平
                key_reg <= key_in;
                cnt     <= 19'd0;
            end
            else
                cnt <= cnt + 19'd1;
        end
        else
            cnt <= 19'd0;               // 电平又变回去了，重新计时
    end

    //------------------------------------------------------- 打一拍
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_reg_d <= 1'b1;
        else
            key_reg_d <= key_reg;
    end

    //------------------------------------------------------- 下降沿 = 点击
    assign key_flag = key_reg_d & (~key_reg);

endmodule
