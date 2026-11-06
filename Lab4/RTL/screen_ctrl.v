`timescale 1ns / 1ps
//=============================================================================
// screen_ctrl.v  --  画面状态机
//
// 三个状态就是三块屏幕，一次点击走一步，转一圈回到起点：
//
//     复位 --+--> BARS --点击--> MUST --点击--> END --点击--> BARS ...
//            |
//            +-- 任何时候拉低复位都回到 BARS
//
// 用 Moore 型：输出 screen 只由当前状态决定，和点击信号无关。
// 状态编码直接就是屏幕编号，vga_pic 拿它选画面，不用再做译码。
//=============================================================================
module screen_ctrl(
    input  wire       clk,        // 25 MHz
    input  wire       rst_n,      // 低电平有效复位
    input  wire       key_flag,   // 来自 key_debounce 的一次点击
    output reg  [1:0] screen      // 0 = 彩条, 1 = MUST, 2 = END
);

    parameter [1:0] S_BARS = 2'd0;
    parameter [1:0] S_MUST = 2'd1;
    parameter [1:0] S_END  = 2'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            screen <= S_BARS;                 // 复位画面固定是彩条
        else begin
            case (screen)
                S_BARS: if (key_flag) screen <= S_MUST;
                S_MUST: if (key_flag) screen <= S_END;
                S_END:  if (key_flag) screen <= S_BARS;
                default: screen <= S_BARS;
            endcase
        end
    end

endmodule
