`timescale 1ns / 1ps
//=============================================================================
// tb_vga_pic.v  --  验证三块屏幕的像素内容
//
// 检查项：
//   1. 彩条：10 条分界处的颜色
//   2. MUST：笔画位置是白、空白位置是黑、框外是黑
//   3. END ：同上
//   4. 整屏统计：MUST 白点 9600（96 个点阵位 x 100），
//                END  白点 7600（76 个点阵位 x 100）
//=============================================================================
module tb_vga_pic;

    reg         vga_clk;
    reg         sys_rst_n;
    reg  [1:0]  screen;
    reg  [9:0]  pix_x, pix_y;
    wire [15:0] pix_data;

    localparam [15:0] BLACK  = 16'h0000;
    localparam [15:0] WHITE  = 16'hFFFF;
    localparam [15:0] RED    = 16'hF800;
    localparam [15:0] ORANGE = 16'hFC00;
    localparam [15:0] YELLOW = 16'hFFE0;
    localparam [15:0] GREEN  = 16'h07E0;
    localparam [15:0] CYAN   = 16'h07FF;
    localparam [15:0] BLUE   = 16'h001F;
    localparam [15:0] PURPLE = 16'hF81F;
    localparam [15:0] GRAY   = 16'hD69A;

    initial vga_clk = 1'b0;
    always #20 vga_clk = ~vga_clk;      // 25 MHz

    vga_pic u_vga_pic (
        .vga_clk   (vga_clk),
        .sys_rst_n (sys_rst_n),
        .screen    (screen),
        .pix_x     (pix_x),
        .pix_y     (pix_y),
        .pix_data  (pix_data)
    );

    integer x, y;
    integer white_cnt, err_cnt;
    reg [15:0] got;

    //------------------------------------------------------ 喂一个坐标看一眼
    task probe(input [1:0] scr, input [9:0] tx, input [9:0] ty, input [15:0] exp);
        begin
            screen = scr; pix_x = tx; pix_y = ty;
            @(posedge vga_clk); #1;
            got = pix_data;
            if (got !== exp) begin
                $display("  FAIL scr=%0d (%0d,%0d): got %h expect %h",
                         scr, tx, ty, got, exp);
                err_cnt = err_cnt + 1;
            end
            else
                $display("  PASS scr=%0d (%0d,%0d): %h", scr, tx, ty, got);
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("tb_vga_pic.vcd");

        sys_rst_n = 1'b0;
        screen = 2'd0;
        pix_x = 10'd0; pix_y = 10'd0;
        err_cnt = 0;

        #100;
        @(posedge vga_clk); #1;
        if (pix_data !== BLACK) begin
            $display("  FAIL 复位：pix_data = %h（期望黑）", pix_data);
            err_cnt = err_cnt + 1;
        end
        else $display("  PASS 复位：黑");

        sys_rst_n = 1'b1;
        @(posedge vga_clk);

        //---------------------------------------------------- 1. 彩条
        $display("--------------------------------------------------");
        $display(" 1. 彩条 10 条分界");
        probe(2'd0, 10'd0,   10'd240, RED);
        probe(2'd0, 10'd63,  10'd240, RED);
        probe(2'd0, 10'd64,  10'd240, ORANGE);
        probe(2'd0, 10'd128, 10'd240, YELLOW);
        probe(2'd0, 10'd192, 10'd240, GREEN);
        probe(2'd0, 10'd256, 10'd240, CYAN);
        probe(2'd0, 10'd320, 10'd240, BLUE);
        probe(2'd0, 10'd384, 10'd240, PURPLE);
        probe(2'd0, 10'd448, 10'd240, BLACK);
        probe(2'd0, 10'd512, 10'd240, WHITE);
        probe(2'd0, 10'd576, 10'd240, GRAY);
        probe(2'd0, 10'd639, 10'd240, GRAY);

        //---------------------------------------------------- 2. MUST
        $display("--------------------------------------------------");
        $display(" 2. MUST");
        probe(2'd1, 10'd0,   10'd0,   BLACK);   // 左上角背景
        probe(2'd1, 10'd100, 10'd200, WHITE);   // M 第 0 行最左
        probe(2'd1, 10'd110, 10'd200, BLACK);   // M 第 0 行第 2 格（点阵为 0）
        probe(2'd1, 10'd110, 10'd210, WHITE);   // M 第 1 行第 2 格（点阵为 1）
        probe(2'd1, 10'd220, 10'd200, WHITE);   // U 左竖笔
        probe(2'd1, 10'd220, 10'd279, BLACK);   // U 第 7 行最左（点阵为 0）
        probe(2'd1, 10'd340, 10'd200, BLACK);   // S 第 0 行最左（点阵为 0）
        probe(2'd1, 10'd350, 10'd200, WHITE);   // S 第 0 行第 2 格
        probe(2'd1, 10'd460, 10'd200, WHITE);   // T 顶横最左
        probe(2'd1, 10'd470, 10'd210, BLACK);   // T 第 1 行第 2 格（竖笔在中间）
        probe(2'd1, 10'd190, 10'd240, BLACK);   // 字母之间

        //---------------------------------------------------- 3. END
        $display("--------------------------------------------------");
        $display(" 3. END");
        probe(2'd2, 10'd0,   10'd0,   BLACK);
        probe(2'd2, 10'd160, 10'd200, WHITE);   // E 顶横最左
        probe(2'd2, 10'd160, 10'd230, WHITE);   // E 中间横线
        probe(2'd2, 10'd170, 10'd210, BLACK);   // E 第 1 行第 2 格（只有左竖笔）
        probe(2'd2, 10'd280, 10'd200, WHITE);   // N 左竖笔
        probe(2'd2, 10'd290, 10'd210, WHITE);   // N 斜笔
        probe(2'd2, 10'd300, 10'd210, BLACK);   // N 第 1 行第 3 格（空白）
        probe(2'd2, 10'd400, 10'd200, WHITE);   // D 顶部
        probe(2'd2, 10'd470, 10'd200, BLACK);   // D 第 0 行最右（点阵为 0）
        probe(2'd2, 10'd470, 10'd210, WHITE);   // D 第 1 行最右（点阵为 1）

        //---------------------------------------------------- 4. 整屏统计
        $display("--------------------------------------------------");
        $dumpvars(0, tb_vga_pic);           // 下面只录一小段演示扫描

        // 先把 MUST 的 M 顶行扫一遍，波形上能看到点阵跳变
        screen = 2'd1;
        for (x = 90; x < 180; x = x + 1) begin
            pix_x = x[9:0]; pix_y = 10'd205;
            @(posedge vga_clk); #1;
        end
        $dumpoff;

        $display(" 4. 整屏白点统计（逐像素扫描 640x480）");
        screen = 2'd1;
        white_cnt = 0;
        for (y = 0; y < 480; y = y + 1) begin
            for (x = 0; x < 640; x = x + 1) begin
                pix_x = x[9:0]; pix_y = y[9:0];
                @(posedge vga_clk); #1;
                if (pix_data === WHITE) white_cnt = white_cnt + 1;
            end
        end
        $display("   MUST 白点 = %0d（期望 9600）", white_cnt);
        if (white_cnt == 9600) $display("  PASS: MUST 白点总数");
        else begin $display("  FAIL: MUST 白点总数"); err_cnt = err_cnt + 1; end

        screen = 2'd2;
        white_cnt = 0;
        for (y = 0; y < 480; y = y + 1) begin
            for (x = 0; x < 640; x = x + 1) begin
                pix_x = x[9:0]; pix_y = y[9:0];
                @(posedge vga_clk); #1;
                if (pix_data === WHITE) white_cnt = white_cnt + 1;
            end
        end
        $display("   END  白点 = %0d（期望 7600）", white_cnt);
        if (white_cnt == 7600) $display("  PASS: END 白点总数");
        else begin $display("  FAIL: END 白点总数"); err_cnt = err_cnt + 1; end

        $display("==================================================");
        if (err_cnt == 0) $display(">>> ALL CHECKS PASSED <<<");
        else              $display(">>> %0d CHECK(S) FAILED <<<", err_cnt);
        $display("==================================================");
        $finish;
    end

endmodule
