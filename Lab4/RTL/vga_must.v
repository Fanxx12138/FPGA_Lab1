`timescale 1ns / 1ps
//=============================================================================
// vga_must.v  --  显示 "MUST"（黑底白字，居中）
//
// 点阵沿用 Lab 3 自己画的 8x8 字体，每个点放大 10 倍 => 每个字母 80x80。
// 四个字母整体宽 440 像素，左边放在 (640-440)/2 = 100，
// 上边放在 (480-80)/2 = 200，这样整行字正好居中。
//
//   M            U            S            T
//   #......#     #......#     .######.     ########
//   ##....##     #......#     ##....##     ...##...
//   #.#..#.#     #......#     ##......     ...##...
//   #..##..#     #......#     .######.     ...##...
//   #......#     #......#     ......##     ...##...
//   #......#     #......#     ......##     ...##...
//   #......#     #......#     ##....##     ...##...
//   #......#     .######.     .######.     ...##...
//=============================================================================
module vga_must(
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output reg  [15:0] pix_data
);

    //----------------------------------------------------------- 8x8 点阵
    // MSB = 最左边的像素，1 = 笔画
    parameter [7:0] M_ROW_0 = 8'b1000_0001;
    parameter [7:0] M_ROW_1 = 8'b1100_0011;
    parameter [7:0] M_ROW_2 = 8'b1010_0101;
    parameter [7:0] M_ROW_3 = 8'b1001_1001;
    parameter [7:0] M_ROW_4 = 8'b1000_0001;
    parameter [7:0] M_ROW_5 = 8'b1000_0001;
    parameter [7:0] M_ROW_6 = 8'b1000_0001;
    parameter [7:0] M_ROW_7 = 8'b1000_0001;

    parameter [7:0] U_ROW_0 = 8'b1000_0001;
    parameter [7:0] U_ROW_1 = 8'b1000_0001;
    parameter [7:0] U_ROW_2 = 8'b1000_0001;
    parameter [7:0] U_ROW_3 = 8'b1000_0001;
    parameter [7:0] U_ROW_4 = 8'b1000_0001;
    parameter [7:0] U_ROW_5 = 8'b1000_0001;
    parameter [7:0] U_ROW_6 = 8'b1000_0001;
    parameter [7:0] U_ROW_7 = 8'b0111_1110;

    parameter [7:0] S_ROW_0 = 8'b0111_1110;
    parameter [7:0] S_ROW_1 = 8'b1100_0011;
    parameter [7:0] S_ROW_2 = 8'b1100_0000;
    parameter [7:0] S_ROW_3 = 8'b0111_1110;
    parameter [7:0] S_ROW_4 = 8'b0000_0011;
    parameter [7:0] S_ROW_5 = 8'b0000_0011;
    parameter [7:0] S_ROW_6 = 8'b1100_0011;
    parameter [7:0] S_ROW_7 = 8'b0111_1110;

    parameter [7:0] T_ROW_0 = 8'b1111_1111;
    parameter [7:0] T_ROW_1 = 8'b0001_1000;
    parameter [7:0] T_ROW_2 = 8'b0001_1000;
    parameter [7:0] T_ROW_3 = 8'b0001_1000;
    parameter [7:0] T_ROW_4 = 8'b0001_1000;
    parameter [7:0] T_ROW_5 = 8'b0001_1000;
    parameter [7:0] T_ROW_6 = 8'b0001_1000;
    parameter [7:0] T_ROW_7 = 8'b0001_1000;

    //----------------------------------------------------------- 位置和颜色
    parameter [9:0] CH_W = 10'd80;      // 字母边长
    parameter [9:0] CH_Y = 10'd200;     // 四个字母共用的上边

    parameter [9:0] M_X = 10'd100;      // 各字母框左边
    parameter [9:0] U_X = 10'd220;
    parameter [9:0] S_X = 10'd340;
    parameter [9:0] T_X = 10'd460;

    parameter [15:0] BG = 16'h0000;     // 黑底
    parameter [15:0] FG = 16'hFFFF;     // 白字

    //----------------------------------------------------------- 框内判断
    wire in_row = (pix_y >= CH_Y) && (pix_y < CH_Y + CH_W);

    wire in_M = in_row && (pix_x >= M_X) && (pix_x < M_X + CH_W);
    wire in_U = in_row && (pix_x >= U_X) && (pix_x < U_X + CH_W);
    wire in_S = in_row && (pix_x >= S_X) && (pix_x < S_X + CH_W);
    wire in_T = in_row && (pix_x >= T_X) && (pix_x < T_X + CH_W);

    //----------------------------------------------------------- 框内行列号
    // 80 像素宽 = 8 格，每格 10 像素，所以 dx/10 就是点阵的第几列
    wire [9:0] x0 = in_M ? M_X : in_U ? U_X : in_S ? S_X : T_X;

    wire [2:0] char_x = (pix_x - x0) / 10;    // 0..7
    wire [2:0] char_y = (pix_y - CH_Y) / 10;  // 0..7

    //----------------------------------------------------------- 输出颜色
    always @(*) begin
        if (in_M) begin
            case (char_y)
                3'd0: pix_data = M_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = M_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = M_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = M_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = M_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = M_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = M_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = M_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else if (in_U) begin
            case (char_y)
                3'd0: pix_data = U_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = U_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = U_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = U_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = U_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = U_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = U_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = U_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else if (in_S) begin
            case (char_y)
                3'd0: pix_data = S_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = S_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = S_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = S_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = S_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = S_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = S_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = S_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else if (in_T) begin
            case (char_y)
                3'd0: pix_data = T_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = T_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = T_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = T_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = T_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = T_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = T_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = T_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else
            pix_data = BG;              // 字母框外面：黑底
    end

endmodule
