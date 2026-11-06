`timescale 1ns / 1ps
//=============================================================================
// tb_vga_top.v  --  顶层联调：屏幕切换、消抖、复位、时序
//
// 检查项：
//   1. 上电复位后是彩条
//   2. 带抖动的点击：状态只在最后一次抖动后约 20 ms 改变，且只改变一次
//   3. 三次点击：彩条 -> MUST -> END -> 彩条（转一圈）
//   4. 长按 60 ms：仍然只切换一次
//   5. 从 MUST / END 复位，以及点击途中复位：都回到彩条
//   6. 每个画面抽查像素颜色（rgb 与 vga_pic 的对应关系）
//   7. hsync / vsync 周期，消隐区 rgb = 0
//
// 波形只录几个变化慢的信号（key_in / key_reg / key_flag / screen），
// 否则 600 ms 的仿真会产生上千万个时间点，CSV 根本处理不了。
//=============================================================================
module tb_vga_top;

    reg         sys_clk;
    reg         sys_rst_n;
    reg         key_in;
    wire        hsync, vsync;
    wire [15:0] rgb;

    localparam [15:0] BLACK = 16'h0000;
    localparam [15:0] WHITE = 16'hFFFF;
    localparam [15:0] RED   = 16'hF800;

    // 50 MHz
    initial sys_clk = 1'b0;
    always #10 sys_clk = ~sys_clk;

    vga_top u_vga_top (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .key_in    (key_in),
        .hsync     (hsync),
        .vsync     (vsync),
        .rgb       (rgb)
    );

    integer err_cnt;
    integer tr_cnt;             // screen 变化次数
    time    t_last_press;       // 最后一次按下（key_in 下降沿）
    time    t_change;           // 最近一次状态变化
    time    t_change_prev;
    time    h_period, v_period;
    time    t_h_prev, t_v_prev;
    integer h_edges, v_edges;
    reg [1:0] screen_prev;

    //------------------------------------------------------ 记录按键按下时刻
    always @(negedge key_in) t_last_press = $time;

    //------------------------------------------------------ 状态变化监视
    // 在下降沿看，避开和时钟块抢同一拍
    always @(negedge u_vga_top.vga_clk) begin
        if (u_vga_top.screen !== screen_prev) begin
            tr_cnt    = tr_cnt + 1;
            t_change  = $time;
            $display("  [%0t] screen: %0d -> %0d，共变化 %0d 次",
                     $time, screen_prev, u_vga_top.screen, tr_cnt);
            if (sys_rst_n)
                $display("         距最后一次按下 %0t（期望约 20 ms）",
                         $time - t_last_press);
            else
                $display("         由复位引起");
            screen_prev = u_vga_top.screen;
        end
    end

    //------------------------------------------------------ 时序测量
    always @(posedge hsync) begin
        if (h_edges > 0) h_period = $time - t_h_prev;
        t_h_prev = $time;
        h_edges  = h_edges + 1;
    end

    always @(posedge vsync) begin
        // 只量最开始的两帧，后面有复位会打断计数
        if (v_edges > 0 && v_edges < 3) v_period = $time - t_v_prev;
        t_v_prev = $time;
        v_edges  = v_edges + 1;
    end

    //------------------------------------------------------ 消隐区必须是黑
    always @(posedge u_vga_top.vga_clk)
        if (sys_rst_n && !u_vga_top.u_vga_ctrl.rgb_valid && rgb !== BLACK) begin
            $display("  ERROR: 消隐区 rgb = %h", rgb);
            err_cnt = err_cnt + 1;
        end

    //------------------------------------------------------ 检查/探针任务
    task expect_screen(input [1:0] exp);
        begin
            if (u_vga_top.screen !== exp) begin
                $display("  FAIL: screen = %0d（期望 %0d）", u_vga_top.screen, exp);
                err_cnt = err_cnt + 1;
            end
            else
                $display("  PASS: screen = %0d", u_vga_top.screen);
        end
    endtask

    // 等到扫描到 (tx,ty) 这个像素，检查 rgb
    // 说明：vga_pic 的输出比 pix_x 晚一拍，所以看到 pix_x = tx+1 时
    //       rgb 正好是 tx 这一列的颜色
    task check_pixel(input [9:0] tx, input [9:0] ty, input [15:0] exp);
        begin : probe_body
            forever begin
                @(negedge u_vga_top.vga_clk);
                if (u_vga_top.pix_x == tx + 10'd1 && u_vga_top.pix_y == ty) begin
                    if (rgb !== exp) begin
                        $display("  FAIL 像素(%0d,%0d) = %h（期望 %h）", tx, ty, rgb, exp);
                        err_cnt = err_cnt + 1;
                    end
                    else
                        $display("  PASS 像素(%0d,%0d) = %h", tx, ty, rgb);
                    disable probe_body;
                end
            end
        end
    endtask

    //------------------------------------------------------ 主激励
    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("tb_vga_top.vcd");
        $dumpvars(0, tb_vga_top.key_in,
                     tb_vga_top.sys_rst_n,
                     tb_vga_top.u_vga_top.key_flag,
                     tb_vga_top.u_vga_top.u_key_debounce.key_reg,
                     tb_vga_top.u_vga_top.screen);

        key_in       = 1'b1;
        sys_rst_n    = 1'b0;
        err_cnt      = 0;
        tr_cnt       = 0;
        t_last_press = 0;
        t_change     = 0;
        h_edges = 0; v_edges = 0;
        screen_prev  = 2'd0;

        #200;
        sys_rst_n = 1'b1;
        #800;                       // t = 1 us

        $display("--------------------------------------------------");
        $display(" 1. 上电复位");
        $display("  检查：复位后是彩条");
        expect_screen(2'd0);

        //================================================= 点击 1：带抖动
        $display("--------------------------------------------------");
        $display(" 2. 带抖动的点击（抖动 8 ms，之后保持按下）");
        #(1000000 - 1000);          // t = 1 ms，开始按

        key_in = 1'b0; #1000000;    // 抖动：每次只保持 1 ms < 20 ms
        key_in = 1'b1; #1000000;
        key_in = 1'b0; #1000000;
        key_in = 1'b1; #1000000;
        key_in = 1'b0; #1000000;
        key_in = 1'b1; #1000000;
        key_in = 1'b0; #1000000;
        key_in = 1'b1; #1000000;
        key_in = 1'b0;              // 真正按下，从这里开始计时 20 ms

        #16000000;                  // 稳定 16 ms，还没到 20 ms 的判断点
        $display("  检查：消抖未完成时仍是彩条");
        expect_screen(2'd0);

        #10000000;                  // 再等 10 ms，累计 26 ms > 20 ms
        $display("  检查：消抖完成后切到 MUST");
        expect_screen(2'd1);
        if (tr_cnt == 1) $display("  PASS: 抖动只引起 1 次切换");
        else begin
            $display("  FAIL: 抖动引起 %0d 次切换", tr_cnt);
            err_cnt = err_cnt + 1;
        end

        //---- MUST 画面抽查像素（按扫描顺序问，省仿真时间）----
        check_pixel(10'd0,   10'd0,   BLACK);   // 背景
        check_pixel(10'd100, 10'd200, WHITE);   // M 左上角笔画
        check_pixel(10'd110, 10'd200, BLACK);   // M 点阵的空白处

        // 松开后要稳定 20 ms，消抖器才认可"已松开"，再按才算新的一次点击
        key_in = 1'b1;
        #22000000;

        //================================================= 点击 2：干净
        $display("--------------------------------------------------");
        $display(" 3. 第二次点击 -> END");
        key_in = 1'b0;
        #25000000;                  // 按住 25 ms
        $display("  检查：第二次点击后是 END");
        expect_screen(2'd2);
        key_in = 1'b1;
        #22000000;

        check_pixel(10'd160, 10'd200, WHITE);   // E 顶横
        check_pixel(10'd470, 10'd200, BLACK);   // D 右上角的空白

        //================================================= 点击 3：长按
        $display("--------------------------------------------------");
        $display(" 4. 第三次点击并长按 40 ms -> 彩条");
        key_in = 1'b0;
        #25000000;
        $display("  检查：第三次点击后回到彩条");
        expect_screen(2'd0);
        #40000000;                  // 再按住 40 ms（总共 65 ms）
        $display("  检查：长按期间不再切换");
        expect_screen(2'd0);
        if (tr_cnt == 3) $display("  PASS: 三次点击共 3 次切换");
        else begin
            $display("  FAIL: 三次点击共 %0d 次切换（期望 3）", tr_cnt);
            err_cnt = err_cnt + 1;
        end
        key_in = 1'b1;
        #22000000;

        check_pixel(10'd0, 10'd240, RED);       // 彩条第一条是红色

        //================================================= 从 END 复位
        $display("--------------------------------------------------");
        $display(" 5. 走到 END 后复位");
        key_in = 1'b0; #25000000; key_in = 1'b1; #22000000;   // -> MUST
        key_in = 1'b0; #25000000; key_in = 1'b1; #22000000;   // -> END
        $display("  检查：复位前是 END");
        expect_screen(2'd2);

        sys_rst_n = 1'b0;
        #1000000;
        $display("  检查：END 状态复位回到彩条");
        expect_screen(2'd0);
        sys_rst_n = 1'b1;
        #2000000;

        //================================================= 按下途中复位
        $display("--------------------------------------------------");
        $display(" 6. 点击途中复位");
        key_in = 1'b0;              // 按下，但还没到 20 ms
        #5000000;                   // 5 ms
        sys_rst_n = 1'b0;
        #5000000;                   // 复位保持 5 ms，此时按键仍按着
        $display("  检查：按着切换键时复位仍回到彩条");
        expect_screen(2'd0);
        sys_rst_n = 1'b1;
        #2000000;
        key_in = 1'b1;              // 松开（稳定低电平只有 7 ms，不够 20 ms）
        #30000000;
        $display("  检查：松开后仍停在彩条");
        expect_screen(2'd0);

        //================================================= 时序结果
        $display("--------------------------------------------------");
        $display(" hsync 周期 = %0t（期望 32000 ns）", h_period);
        $display(" vsync 周期 = %0t（期望 16800000 ns）", v_period);
        if (h_period == 32000)     $display("  PASS: hsync 周期");
        else begin $display("  FAIL: hsync 周期"); err_cnt = err_cnt + 1; end
        if (v_period == 16800000)  $display("  PASS: vsync 周期");
        else begin $display("  FAIL: vsync 周期"); err_cnt = err_cnt + 1; end

        $display("==================================================");
        if (err_cnt == 0) $display(">>> ALL CHECKS PASSED <<<");
        else              $display(">>> %0d CHECK(S) FAILED <<<", err_cnt);
        $display("==================================================");
        $finish;
    end

endmodule
