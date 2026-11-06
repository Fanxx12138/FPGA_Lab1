`timescale 1ns / 1ps
//=============================================================================
// vga_top.v  --  顶层：只做连线
//
// 端口和 Lab 4 要求书一致：
//     sys_clk   50 MHz
//     sys_rst_n 低电平有效复位（异步，直接送到各个模块）
//     key_in    低电平有效切换按键
//     hsync / vsync / rgb[15:0]
//
// 信号流向：
//     key_in -> 消抖 -> 一次点击 -> 状态机 -> 当前画面号
//     当前画面号 + 像素坐标 -> 选颜色 -> VGA 时序模块 -> rgb
//=============================================================================
module vga_top(
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire        key_in,
    output wire        hsync,
    output wire        vsync,
    output wire [15:0] rgb
);

    wire        vga_clk;      // 25 MHz 像素时钟
    wire        key_flag;     // 一次点击（一个时钟周期的脉冲）
    wire [1:0]  screen;       // 当前画面 0/1/2
    wire [9:0]  pix_x;        // 当前像素 x 坐标
    wire [9:0]  pix_y;        // 当前像素 y 坐标
    wire [15:0] pix_data;     // 像素颜色

    //------------------------------------------------------------ 时钟分频
    vga_pll u_vga_pll (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .vga_clk   (vga_clk)
    );

    //------------------------------------------------------------ 按键消抖
    key_debounce u_key_debounce (
        .clk      (vga_clk),
        .rst_n    (sys_rst_n),
        .key_in   (key_in),
        .key_flag (key_flag)
    );

    //------------------------------------------------------------ 画面状态机
    screen_ctrl u_screen_ctrl (
        .clk      (vga_clk),
        .rst_n    (sys_rst_n),
        .key_flag (key_flag),
        .screen   (screen)
    );

    //------------------------------------------------------------ 图像内容
    vga_pic u_vga_pic (
        .vga_clk   (vga_clk),
        .sys_rst_n (sys_rst_n),
        .screen    (screen),
        .pix_x     (pix_x),
        .pix_y     (pix_y),
        .pix_data  (pix_data)
    );

    //------------------------------------------------------------ 时序控制
    vga_ctrl u_vga_ctrl (
        .vga_clk   (vga_clk),
        .sys_rst_n (sys_rst_n),
        .pix_data  (pix_data),
        .pix_x     (pix_x),
        .pix_y     (pix_y),
        .hsync     (hsync),
        .vsync     (vsync),
        .rgb       (rgb)
    );

endmodule
