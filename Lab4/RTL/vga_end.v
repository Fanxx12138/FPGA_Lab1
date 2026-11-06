`timescale 1ns / 1ps
//=============================================================================
// vga_end.v  --  显示 "END"（黑底白字，居中）
//
// 和 vga_must 同一套写法：8x8 点阵放大 10 倍，每个字母 80x80。
// 三个字母整体宽 3x80 + 2x40 = 320 像素，左边放在 (640-320)/2 = 160，
// 上边同样放在 (480-80)/2 = 200。
//
//   E            N            D
//   ########     #......#     ######..
//   #......      ##.....#     #......#
//   #......      #.#....#     #......#
//   ######.      #..#...#     #......#
//   #......      #...#..#     #......#
//   #......      #....#.#     #......#
//   #......      #.....##     #......#
//   ########     #......#     ######..
//=============================================================================
module vga_end(
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output reg  [15:0] pix_data
);

    //----------------------------------------------------------- 8x8 点阵
    parameter [7:0] E_ROW_0 = 8'b1111_1111;
    parameter [7:0] E_ROW_1 = 8'b1000_0000;
    parameter [7:0] E_ROW_2 = 8'b1000_0000;
    parameter [7:0] E_ROW_3 = 8'b1111_1110;
    parameter [7:0] E_ROW_4 = 8'b1000_0000;
    parameter [7:0] E_ROW_5 = 8'b1000_0000;
    parameter [7:0] E_ROW_6 = 8'b1000_0000;
    parameter [7:0] E_ROW_7 = 8'b1111_1111;

    parameter [7:0] N_ROW_0 = 8'b1000_0001;
    parameter [7:0] N_ROW_1 = 8'b1100_0001;
    parameter [7:0] N_ROW_2 = 8'b1010_0001;
    parameter [7:0] N_ROW_3 = 8'b1001_0001;
    parameter [7:0] N_ROW_4 = 8'b1000_1001;
    parameter [7:0] N_ROW_5 = 8'b1000_0101;
    parameter [7:0] N_ROW_6 = 8'b1000_0011;
    parameter [7:0] N_ROW_7 = 8'b1000_0001;

    parameter [7:0] D_ROW_0 = 8'b1111_1100;
    parameter [7:0] D_ROW_1 = 8'b1000_0011;
    parameter [7:0] D_ROW_2 = 8'b1000_0001;
    parameter [7:0] D_ROW_3 = 8'b1000_0001;
    parameter [7:0] D_ROW_4 = 8'b1000_0001;
    parameter [7:0] D_ROW_5 = 8'b1000_0001;
    parameter [7:0] D_ROW_6 = 8'b1000_0011;
    parameter [7:0] D_ROW_7 = 8'b1111_1100;

    //----------------------------------------------------------- 位置和颜色
    parameter [9:0] CH_W = 10'd80;      // 字母边长
    parameter [9:0] CH_Y = 10'd200;     // 三个字母共用的上边

    parameter [9:0] E_X = 10'd160;      // 各字母框左边
    parameter [9:0] N_X = 10'd280;
    parameter [9:0] D_X = 10'd400;

    parameter [15:0] BG = 16'h0000;     // 黑底
    parameter [15:0] FG = 16'hFFFF;     // 白字

    //----------------------------------------------------------- 框内判断
    wire in_row = (pix_y >= CH_Y) && (pix_y < CH_Y + CH_W);

    wire in_E = in_row && (pix_x >= E_X) && (pix_x < E_X + CH_W);
    wire in_N = in_row && (pix_x >= N_X) && (pix_x < N_X + CH_W);
    wire in_D = in_row && (pix_x >= D_X) && (pix_x < D_X + CH_W);

    //----------------------------------------------------------- 框内行列号
    wire [9:0] x0 = in_E ? E_X : in_N ? N_X : D_X;

    wire [2:0] char_x = (pix_x - x0) / 10;    // 0..7
    wire [2:0] char_y = (pix_y - CH_Y) / 10;  // 0..7

    //----------------------------------------------------------- 输出颜色
    always @(*) begin
        if (in_E) begin
            case (char_y)
                3'd0: pix_data = E_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = E_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = E_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = E_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = E_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = E_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = E_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = E_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else if (in_N) begin
            case (char_y)
                3'd0: pix_data = N_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = N_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = N_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = N_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = N_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = N_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = N_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = N_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else if (in_D) begin
            case (char_y)
                3'd0: pix_data = D_ROW_0[3'd7 - char_x] ? FG : BG;
                3'd1: pix_data = D_ROW_1[3'd7 - char_x] ? FG : BG;
                3'd2: pix_data = D_ROW_2[3'd7 - char_x] ? FG : BG;
                3'd3: pix_data = D_ROW_3[3'd7 - char_x] ? FG : BG;
                3'd4: pix_data = D_ROW_4[3'd7 - char_x] ? FG : BG;
                3'd5: pix_data = D_ROW_5[3'd7 - char_x] ? FG : BG;
                3'd6: pix_data = D_ROW_6[3'd7 - char_x] ? FG : BG;
                3'd7: pix_data = D_ROW_7[3'd7 - char_x] ? FG : BG;
                default: pix_data = BG;
            endcase
        end
        else
            pix_data = BG;              // 字母框外面：黑底
    end

endmodule
