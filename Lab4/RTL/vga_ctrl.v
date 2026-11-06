`timescale 1ns / 1ps
//=============================================================================
// vga_ctrl.v  --  VGA 时序控制器（640x480@60）
//
// 参数全部来自 VESA DMT v1.13，640x480@60 这一行：
//   H: Sync 96, Back Porch 40, Left Border 8, Addressable 640,
//      Right Border 8, Front Porch 8, Total 800
//   V: Sync  2, Back Porch 25, Top  Border 8, Addressable 480,
//      Bottom Border 8, Front Porch 2, Total 525
//
// 本模块只负责"数拍子"，完全不知道屏幕上画什么。
// 图像内容由 vga_pic 决定，二者之间只通过 pix_x/pix_y 和 pix_data 连接。
//=============================================================================
module vga_ctrl(
    input  wire        vga_clk,     // 25 MHz 像素时钟
    input  wire        sys_rst_n,   // 低电平有效复位
    input  wire [15:0] pix_data,    // 来自 vga_pic 的颜色

    output wire [9:0]  pix_x,       // 当前像素 x 坐标 0..639
    output wire [9:0]  pix_y,       // 当前像素 y 坐标 0..479
    output wire        hsync,       // 行同步
    output wire        vsync,       // 场同步
    output wire [15:0] rgb          // RGB565，送 VGA 接口
);

    //------------------------------------------------------------------ 参数
    // 水平方向（单位：像素时钟）
    parameter [9:0] H_SYNC  = 10'd96;
    parameter [9:0] H_BACK  = 10'd40;
    parameter [9:0] H_LEFT  = 10'd8;
    parameter [9:0] H_VALID = 10'd640;
    parameter [9:0] H_RIGHT = 10'd8;
    parameter [9:0] H_FRONT = 10'd8;
    parameter [9:0] H_TOTAL = 10'd800;

    // 垂直方向（单位：行）
    parameter [9:0] V_SYNC   = 10'd2;
    parameter [9:0] V_BACK   = 10'd25;
    parameter [9:0] V_TOP    = 10'd8;
    parameter [9:0] V_VALID  = 10'd480;
    parameter [9:0] V_BOTTOM = 10'd8;
    parameter [9:0] V_FRONT  = 10'd2;
    parameter [9:0] V_TOTAL  = 10'd525;

    //-------------------------------------------------------------- 内部信号
    reg  [9:0] cnt_h;           // 行内像素计数 0..799
    reg  [9:0] cnt_v;           // 帧内行计数   0..524

    wire       rgb_valid;       // 当前是否在 640x480 可见区
    wire       pix_data_req;    // 当前是否向 vga_pic 要颜色（比 valid 早一拍）

    //------------------------------------------------------------ 行计数器
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cnt_h <= 10'd0;
        else if (cnt_h == H_TOTAL - 10'd1)   // 数到 799 回零
            cnt_h <= 10'd0;
        else
            cnt_h <= cnt_h + 10'd1;
    end

    //------------------------------------------------------------ 场计数器
    // 只在"一行走完"的那一拍加 1
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cnt_v <= 10'd0;
        else if (cnt_h == H_TOTAL - 10'd1) begin
            if (cnt_v == V_TOTAL - 10'd1)    // 数到 524 回零
                cnt_v <= 10'd0;
            else
                cnt_v <= cnt_v + 10'd1;
        end
        else
            cnt_v <= cnt_v;
    end

    //----------------------------------------------------------- 同步信号
    // 一行/一帧的开头先给同步脉冲，和 VESA 时序图的顺序一致
    assign hsync = (cnt_h <= H_SYNC - 10'd1) ? 1'b1 : 1'b0;
    assign vsync = (cnt_v <= V_SYNC - 10'd1) ? 1'b1 : 1'b0;

    //--------------------------------------------------- 可见窗口 / 请求窗口
    // rgb_valid：真正的 640x480 可见区
    assign rgb_valid = ( (cnt_h >= H_SYNC + H_BACK + H_LEFT)
                      && (cnt_h <  H_SYNC + H_BACK + H_LEFT + H_VALID) )
                    && ( (cnt_v >= V_SYNC + V_BACK + V_TOP)
                      && (cnt_v <  V_SYNC + V_BACK + V_TOP + V_VALID) )
                       ? 1'b1 : 1'b0;

    // pix_data_req：和 rgb_valid 相同，但水平方向提前一个像素
    // 因为 vga_pic 的 pix_data 是寄存器输出，晚一拍才有效
    assign pix_data_req = ( (cnt_h >= H_SYNC + H_BACK + H_LEFT - 10'd1)
                         && (cnt_h <  H_SYNC + H_BACK + H_LEFT + H_VALID - 10'd1) )
                       && ( (cnt_v >= V_SYNC + V_BACK + V_TOP)
                         && (cnt_v <  V_SYNC + V_BACK + V_TOP + V_VALID) )
                          ? 1'b1 : 1'b0;

    //--------------------------------------------------------------- 坐标
    // 把"绝对计数"平移成"图像坐标"：可见区第一列 -> 0，第一行 -> 0
    // 不在请求窗口时给 10'h3ff（1023）作为"无效"标记
    assign pix_x = (pix_data_req == 1'b1)
                 ? (cnt_h - (H_SYNC + H_BACK + H_LEFT - 10'd1))
                 : 10'h3ff;

    assign pix_y = (pix_data_req == 1'b1)
                 ? (cnt_v - (V_SYNC + V_BACK + V_TOP))
                 : 10'h3ff;

    //---------------------------------------------------------------- rgb
    // 可见区输出图像颜色，消隐区强制送黑，避免边缘出现杂色
    assign rgb = (rgb_valid == 1'b1) ? pix_data : 16'h0000;

endmodule
