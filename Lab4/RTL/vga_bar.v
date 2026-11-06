`timescale 1ns / 1ps
//=============================================================================
// vga_bar.v  --  彩条画面
//
// 屏幕横向 640 像素分成 10 条，每条 64 像素，颜色照讲义例子：
//   红 橙 黄 绿 青 蓝 紫 黑 白 灰
//
// 这是一个纯组合电路：告诉它 x 坐标，它给一个颜色。
// 颜色在 vga_pic 里统一打一拍，所以这里不用时钟。
//=============================================================================
module vga_bar(
    input  wire [9:0]  pix_x,     // 当前像素 x 坐标 0..639
    output reg  [15:0] pix_data   // RGB565 颜色
);

    //----------------------------------------------------------- 颜色（RGB565）
    parameter [15:0] RED    = 16'hF800;
    parameter [15:0] ORANGE = 16'hFC00;
    parameter [15:0] YELLOW = 16'hFFE0;
    parameter [15:0] GREEN  = 16'h07E0;
    parameter [15:0] CYAN   = 16'h07FF;
    parameter [15:0] BLUE   = 16'h001F;
    parameter [15:0] PURPLE = 16'hF81F;
    parameter [15:0] BLACK  = 16'h0000;
    parameter [15:0] WHITE  = 16'hFFFF;
    parameter [15:0] GRAY   = 16'hD69A;

    //----------------------------------------------------------- 按列选颜色
    // 640 / 10 = 64 像素一条
    always @(*) begin
        if      (pix_x < 10'd64 ) pix_data = RED;
        else if (pix_x < 10'd128) pix_data = ORANGE;
        else if (pix_x < 10'd192) pix_data = YELLOW;
        else if (pix_x < 10'd256) pix_data = GREEN;
        else if (pix_x < 10'd320) pix_data = CYAN;
        else if (pix_x < 10'd384) pix_data = BLUE;
        else if (pix_x < 10'd448) pix_data = PURPLE;
        else if (pix_x < 10'd512) pix_data = BLACK;
        else if (pix_x < 10'd576) pix_data = WHITE;
        else if (pix_x < 10'd640) pix_data = GRAY;
        else                      pix_data = BLACK;
    end

endmodule
