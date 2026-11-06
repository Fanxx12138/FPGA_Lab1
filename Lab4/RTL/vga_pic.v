`timescale 1ns / 1ps
//=============================================================================
// vga_pic.v  --  按当前画面选颜色
//
// 三种画面各写成一个独立的小模块，这里只负责"三选一"：
//   screen = 0 -> vga_bar   彩条
//   screen = 1 -> vga_must  MUST
//   screen = 2 -> vga_end   END
//
// 为什么拆成三个模块：每块屏幕的内容互不相干，拆开后
//   - 每个模块只关心自己的一张图，代码短、好查错；
//   - 以后改某一屏不会碰到另外两屏；
//   - 代价只是多两个模块名，不是多出来的逻辑。
//
// 三个画面都是组合逻辑，最后在这里统一打一拍输出，
// 和 vga_ctrl 的 pix_data_req 提前一像素的约定对得上。
//=============================================================================
module vga_pic(
    input  wire        vga_clk,
    input  wire        sys_rst_n,
    input  wire [1:0]  screen,      // 0 = 彩条, 1 = MUST, 2 = END
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output reg  [15:0] pix_data
);

    wire [15:0] bar_data;       // 彩条画面
    wire [15:0] must_data;      // MUST 画面
    wire [15:0] end_data;       // END 画面

    vga_bar u_vga_bar (
        .pix_x    (pix_x),
        .pix_data (bar_data)
    );

    vga_must u_vga_must (
        .pix_x    (pix_x),
        .pix_y    (pix_y),
        .pix_data (must_data)
    );

    vga_end u_vga_end (
        .pix_x    (pix_x),
        .pix_y    (pix_y),
        .pix_data (end_data)
    );

    //------------------------------------------------------- 三选一后打一拍
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            pix_data <= 16'h0000;
        else begin
            case (screen)
                2'd0:    pix_data <= bar_data;
                2'd1:    pix_data <= must_data;
                2'd2:    pix_data <= end_data;
                default: pix_data <= 16'h0000;
            endcase
        end
    end

endmodule
