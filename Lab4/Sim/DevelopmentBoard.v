`timescale 1ns / 1ps
//=============================================================================
// DevelopmentBoard.v  --  Simple VGA Simulator 的板级外壳
//
// 模拟器固定提供这些端口：
//   clk   50 MHz
//   reset 复位按键（低有效，对应键盘 a）
//   B2~B5 四个按键（低有效，对应键盘 s d f g）
//   h_sync / v_sync / rgb  接模拟器的 VGA 窗口
//   led1~led5              接模拟器下方的 LED
//
// 本实验只用一个切换按键，映射到 B2（键盘 s）。
//=============================================================================
module DevelopmentBoard(
    input  wire        clk,             // 50 MHz
    input  wire        reset,           // 低有效，键盘 a
    input  wire        B2, B3, B4, B5,  // 低有效，键盘 s d f g

    output wire        h_sync,
    output wire        v_sync,
    output wire [15:0] rgb,

    output wire        led1,
    output wire        led2,
    output wire        led3,
    output wire        led4,
    output wire        led5
);

    vga_top u_vga_top (
        .sys_clk   (clk),
        .sys_rst_n (reset),
        .key_in    (B2),
        .hsync     (h_sync),
        .vsync     (v_sync),
        .rgb       (rgb)
    );

    // 本实验没有用到 LED，全部保持熄灭
    assign led1 = 1'b1;
    assign led2 = 1'b1;
    assign led3 = 1'b1;
    assign led4 = 1'b1;
    assign led5 = 1'b1;

endmodule
