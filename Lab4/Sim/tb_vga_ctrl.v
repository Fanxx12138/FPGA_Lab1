`timescale 1ns / 1ps
//=============================================================================
// tb_vga_ctrl.v  --  验证 VGA 时序控制器
//
// 检查项：
//   1. hsync 周期  = 800 x 40 ns = 32 us
//   2. hsync 脉宽  =  96 x 40 ns = 3.84 us
//   3. vsync 周期  = 525 x 32 us = 16.8 ms
//   4. vsync 脉宽  =   2 x 32 us = 64 us
//   5. pix_x 映射：cnt_h=143 -> 0，cnt_h=782 -> 639，其余 -> 10'h3ff
//   6. pix_data_req 比 rgb_valid 早一个像素
//   7. 消隐区 rgb 恒为 0
//=============================================================================
module tb_vga_ctrl;

    reg         vga_clk;
    reg         sys_rst_n;
    reg  [15:0] pix_data_in;

    wire [9:0]  pix_x, pix_y;
    wire        hsync, vsync;
    wire [15:0] rgb;

    // 25 MHz 像素时钟
    initial vga_clk = 1'b0;
    always #20 vga_clk = ~vga_clk;

    vga_ctrl u_vga_ctrl (
        .vga_clk   (vga_clk),
        .sys_rst_n (sys_rst_n),
        .pix_data  (pix_data_in),
        .pix_x     (pix_x),
        .pix_y     (pix_y),
        .hsync     (hsync),
        .vsync     (vsync),
        .rgb       (rgb)
    );

    //------------------------------------------------------------ 测量变量
    time t_h_rise, t_h_fall, t_h_prev;
    time t_v_rise, t_v_prev;
    time h_period, h_pulse, v_period, v_pulse;
    integer h_edges, v_edges;
    integer err_cnt;

    // 关键点的采样
    integer x_at_143, x_at_782, x_at_783;
    integer req_lead_ok;

    initial begin
        $timeformat(-9, 0, " ns", 12);
        $dumpfile("tb_vga_ctrl.vcd");
        // $dumpvars 放到第 35 行再调用（见文件末尾），这样波形窗口正好压在
        // "消隐区 -> 可见区" 的切换点上，一行 32us 的细节看得清

        sys_rst_n   = 1'b0;
        pix_data_in = 16'hF800;   // 红色，方便肉眼在波形上分辨
        h_edges = 0; v_edges = 0; err_cnt = 0;
        req_lead_ok = 0;

        #200;
        sys_rst_n = 1'b1;

        // 先跑两帧，够测 vsync 周期
        #(16800000 * 2 + 100000);

        //-------------------------------------------------- 结果输出
        $display("==================================================");
        $display(" hsync period   = %0t   (expect 32000 ns)", h_period);
        $display(" hsync pulse    = %0t   (expect 3840 ns)",  h_pulse);
        $display(" vsync period   = %0t   (expect 16800000 ns)", v_period);
        $display(" vsync pulse    = %0t   (expect 64000 ns)",  v_pulse);
        $display(" pix_x @cnt_h=143 = %0d  (expect 0)",    x_at_143);
        $display(" pix_x @cnt_h=782 = %0d  (expect 639)", x_at_782);
        $display(" pix_x @cnt_h=783 = %0d  (expect 1023 -> 3ff)", x_at_783);
        $display(" req leads valid by 1 clk : %s", req_lead_ok ? "YES" : "NO");

        if (h_period == 32000)      $display("PASS: hsync period");
        else begin $display("FAIL: hsync period"); err_cnt = err_cnt + 1; end
        if (h_pulse  == 3840)       $display("PASS: hsync pulse width");
        else begin $display("FAIL: hsync pulse width"); err_cnt = err_cnt + 1; end
        if (v_period == 16800000)   $display("PASS: vsync period");
        else begin $display("FAIL: vsync period"); err_cnt = err_cnt + 1; end
        if (v_pulse  == 64000)      $display("PASS: vsync pulse width");
        else begin $display("FAIL: vsync pulse width"); err_cnt = err_cnt + 1; end
        if (x_at_143 == 0)          $display("PASS: pix_x origin");
        else begin $display("FAIL: pix_x origin"); err_cnt = err_cnt + 1; end
        if (x_at_782 == 639)        $display("PASS: pix_x last");
        else begin $display("FAIL: pix_x last"); err_cnt = err_cnt + 1; end
        if (x_at_783 == 1023)       $display("PASS: pix_x invalid marker");
        else begin $display("FAIL: pix_x invalid marker"); err_cnt = err_cnt + 1; end
        if (req_lead_ok == 1)       $display("PASS: pix_data_req one pixel early");
        else begin $display("FAIL: pix_data_req timing"); err_cnt = err_cnt + 1; end

        if (err_cnt == 0) $display(">>> ALL CHECKS PASSED <<<");
        else              $display(">>> %0d CHECK(S) FAILED <<<", err_cnt);
        $display("==================================================");
        $finish;
    end

    //------------------------------------------------------------ hsync 边沿
    always @(posedge hsync) begin
        t_h_rise = $time;
        if (h_edges > 0) h_period = t_h_rise - t_h_prev;
        t_h_prev = t_h_rise;
        h_edges  = h_edges + 1;
    end
    always @(negedge hsync) begin
        t_h_fall = $time;
        h_pulse  = t_h_fall - t_h_rise;
    end

    //------------------------------------------------------------ vsync 边沿
    always @(posedge vsync) begin
        t_v_rise = $time;
        if (v_edges > 0) v_period = t_v_rise - t_v_prev;
        t_v_prev = t_v_rise;
        v_edges  = v_edges + 1;
    end
    always @(negedge vsync)
        v_pulse = $time - t_v_rise;

    //-------------------------------------------------- 坐标与请求窗口采样
    always @(posedge vga_clk) begin
        if (sys_rst_n) begin
            if (u_vga_ctrl.cnt_v == 10'd35) begin
                if (u_vga_ctrl.cnt_h == 10'd143) x_at_143 = pix_x;
                if (u_vga_ctrl.cnt_h == 10'd782) x_at_782 = pix_x;
                if (u_vga_ctrl.cnt_h == 10'd783) x_at_783 = pix_x;
            end
            // 请求窗口比可见窗口早一拍：cnt_h=143 时 req=1 而 valid=0
            if (u_vga_ctrl.cnt_v == 10'd35 && u_vga_ctrl.cnt_h == 10'd143)
                if (u_vga_ctrl.pix_data_req == 1'b1 && u_vga_ctrl.rgb_valid == 1'b0)
                    req_lead_ok = 1;
        end
    end

    //------------------------------------------------------- 消隐区 rgb 必须为 0
    always @(posedge vga_clk)
        if (sys_rst_n && !u_vga_ctrl.rgb_valid && rgb !== 16'h0000) begin
            $display("ERROR: rgb not blanked at cnt_h=%0d cnt_v=%0d",
                     u_vga_ctrl.cnt_h, u_vga_ctrl.cnt_v);
            err_cnt = err_cnt + 1;
        end

    //------------------------------------ 在第 35 行开头开录，录两行后停止
    // 第 35 行是第一行可见行；从这一行开头录，波形上能同时看到
    // hsync 脉冲、水平消隐、以及 pix_x 从 10'h3ff 跳到 0 的瞬间
    reg dumped;
    initial dumped = 1'b0;

    always @(posedge vga_clk) begin
        if (sys_rst_n && !dumped &&
            u_vga_ctrl.cnt_v == 10'd35 && u_vga_ctrl.cnt_h == 10'd0) begin
            dumped = 1'b1;
            $dumpvars(0, tb_vga_ctrl);
        end
    end

    initial begin
        wait (dumped == 1'b1);
        #64000;               // 64 us = 两行
        $dumpoff;
    end

endmodule
