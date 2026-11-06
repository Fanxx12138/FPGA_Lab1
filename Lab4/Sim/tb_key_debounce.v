`timescale 1ns / 1ps
//=============================================================================
// tb_key_debounce.v  --  验证按键消抖和"一次点击一个脉冲"
//
// 说明：20 ms 消抖在波形上要 500000 个时钟点，VCD/CSV 会大到无法处理。
//       所以这个测试台把 CNT_MAX 缩小到 99（4 us @ 25 MHz），
//       只验证"逻辑对不对"：抖动期间不响应、电平稳定后才认可、
//       按住多久都只出一个脉冲。真实的 20 ms 时间由 tb_vga_top 检查。
//
// 检查项：
//   1. 短于消抖时间的毛刺不产生脉冲
//   2. 带抖动的按下只产生 1 个脉冲，且在最后一次抖动后约 100 个时钟出现
//   3. 一直按住再久也只有 1 个脉冲
//   4. 松开不产生脉冲
//=============================================================================
module tb_key_debounce;

    reg  clk;
    reg  rst_n;
    reg  key_in;
    wire key_flag;

    integer pulse_cnt;      // 脉冲个数
    integer err_cnt;
    time    t_last_press;   // 最后一次"按下电平"出现的时刻

    // 25 MHz
    initial clk = 1'b0;
    always #20 clk = ~clk;

    key_debounce #(
        .CNT_MAX (19'd99)          // 4 us，只是为了仿真看得清
    ) u_key_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .key_in   (key_in),
        .key_flag (key_flag)
    );

    //------------------------------------------------------------ 脉冲计数
    always @(posedge clk) begin
        if (key_flag && rst_n) begin
            pulse_cnt = pulse_cnt + 1;
            $display("  [%0t] key_flag 脉冲 #%0d，距最后一次按下 %0t",
                     $time, pulse_cnt, $time - t_last_press);
        end
    end

    //------------------------------------------------------------ 激励
    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("tb_key_debounce.vcd");
        $dumpvars(0, tb_key_debounce);

        key_in    = 1'b1;
        rst_n     = 1'b0;
        pulse_cnt = 0;
        err_cnt   = 0;
        t_last_press = 0;

        #100;
        rst_n = 1'b1;
        #100;

        //---- 1. 毛刺：20 个时钟（800 ns）的低电平，短于 99 个时钟 ----
        $display("--------------------------------------------------");
        $display(" 1. 短毛刺 20 个时钟");
        key_in = 1'b0; #800;
        key_in = 1'b1;
        #4000;                       // 等足够久
        if (pulse_cnt == 0) $display("  PASS: 毛刺被滤掉");
        else begin
            $display("  FAIL: 毛刺产生了 %0d 个脉冲", pulse_cnt);
            err_cnt = err_cnt + 1;
        end

        //---- 2. 带抖动的按下：3 次来回，最后保持低电平 ----
        $display("--------------------------------------------------");
        $display(" 2. 带抖动的按下（抖动 3 次后保持）");
        key_in = 1'b0; #100;         // 第一次接触
        key_in = 1'b1; #120;         // 弹开
        key_in = 1'b0; #80;          // 再接触
        key_in = 1'b1; #160;         // 再弹开
        key_in = 1'b0;               // 最后真正按下
        t_last_press = $time;

        #(104 * 40);                 // 100 个时钟 = 4 us，再多等一点
        if (pulse_cnt == 1) $display("  PASS: 抖动后只产生 1 个脉冲");
        else begin
            $display("  FAIL: 抖动后产生 %0d 个脉冲（期望 1）", pulse_cnt);
            err_cnt = err_cnt + 1;
        end

        //---- 3. 继续按住 200 个时钟，不应该再出脉冲 ----
        $display("--------------------------------------------------");
        $display(" 3. 一直按住（再等 200 个时钟）");
        #(200 * 40);
        if (pulse_cnt == 1) $display("  PASS: 长按仍然只有 1 个脉冲");
        else begin
            $display("  FAIL: 长按产生了 %0d 个脉冲（期望 1）", pulse_cnt);
            err_cnt = err_cnt + 1;
        end

        //---- 4. 松开 ----
        $display("--------------------------------------------------");
        $display(" 4. 松开按键");
        key_in = 1'b1;
        #(300 * 40);
        if (pulse_cnt == 1) $display("  PASS: 松开不产生脉冲");
        else begin
            $display("  FAIL: 松开产生了脉冲");
            err_cnt = err_cnt + 1;
        end

        //---- 5. 再按一次，确认还能正常工作 ----
        key_in = 1'b0;
        t_last_press = $time;
        #(104 * 40);
        key_in = 1'b1;
        if (pulse_cnt == 2) $display("  PASS: 第二次按下产生第 2 个脉冲");
        else begin
            $display("  FAIL: 第二次按下后脉冲数 = %0d（期望 2）", pulse_cnt);
            err_cnt = err_cnt + 1;
        end

        #2000;
        $display("==================================================");
        if (err_cnt == 0) $display(">>> ALL CHECKS PASSED <<<");
        else              $display(">>> %0d CHECK(S) FAILED <<<", err_cnt);
        $display("==================================================");
        $finish;
    end

endmodule
