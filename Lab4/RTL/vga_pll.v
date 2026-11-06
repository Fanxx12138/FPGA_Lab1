`timescale 1ns / 1ps
//=============================================================================
// vga_pll.v  --  50 MHz -> 25 MHz 像素时钟（二分频）
//
// 与 Lab 3 完全相同，原样复用。
//     800 像素/行 x 525 行/帧 x 60 帧/秒 = 25.2 MHz
//     板载 50 MHz 二分频得 25 MHz，误差 0.8%，在 VGA 显示器容差内。
//=============================================================================
module vga_pll(
    input  wire sys_clk,        // 50 MHz 板载时钟
    input  wire sys_rst_n,      // 低电平有效复位
    output reg  vga_clk         // 25 MHz 像素时钟
);

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            vga_clk <= 1'b0;
        else
            vga_clk <= ~vga_clk;   // 每来一个上升沿翻转一次 => 二分频
    end

endmodule
