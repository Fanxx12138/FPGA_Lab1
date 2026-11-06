`timescale 1ns / 1ps
//=============================================================================
// tb_screen_ctrl.v  --  验证画面状态机
//
// 检查项：
//   1. 复位后是彩条（screen = 0）
//   2. 连续四次点击：0 -> 1 -> 2 -> 0 -> 1（三次一圈，第四次数到 MUST）
//   3. 没有点击时状态保持
//   4. 在任意状态复位都回到 0
//=============================================================================
module tb_screen_ctrl;

    reg       clk;
    reg       rst_n;
    reg       key_flag;
    wire [1:0] screen;

    integer err_cnt;

    initial clk = 1'b0;
    always #20 clk = ~clk;        // 25 MHz

    screen_ctrl u_screen_ctrl (
        .clk      (clk),
        .rst_n    (rst_n),
        .key_flag (key_flag),
        .screen   (screen)
    );

    // 给一个时钟周期的点击脉冲，然后在下降沿检查状态
    task click(input [1:0] expect);
        begin
            @(posedge clk);
            key_flag = 1'b1;
            @(posedge clk);
            key_flag = 1'b0;
            #1;
            if (screen !== expect) begin
                $display("  FAIL: 点击后 screen = %0d（期望 %0d）", screen, expect);
                err_cnt = err_cnt + 1;
            end
            else
                $display("  PASS: screen = %0d", screen);
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("tb_screen_ctrl.vcd");
        $dumpvars(0, tb_screen_ctrl);

        key_flag = 1'b0;
        rst_n    = 1'b0;
        err_cnt  = 0;

        #100;
        //---- 1. 复位 ----
        if (screen !== 2'd0) begin
            $display("  FAIL: 复位后 screen = %0d（期望 0）", screen);
            err_cnt = err_cnt + 1;
        end
        else $display("  PASS: 复位后是彩条");

        rst_n = 1'b1;
        #100;

        //---- 2. 连续点击 ----
        $display("--------------------------------------------------");
        click(2'd1);
        click(2'd2);
        click(2'd0);
        click(2'd1);

        //---- 3. 不点击时保持 ----
        $display("--------------------------------------------------");
        #5000;
        if (screen !== 2'd1) begin
            $display("  FAIL: 无点击时状态自己变了 (%0d)", screen);
            err_cnt = err_cnt + 1;
        end
        else $display("  PASS: 无点击时状态保持");

        //---- 4. 从 MUST 复位 ----
        #100;
        rst_n = 1'b0;
        #100;
        if (screen !== 2'd0) begin
            $display("  FAIL: MUST 状态复位后 screen = %0d", screen);
            err_cnt = err_cnt + 1;
        end
        else $display("  PASS: MUST 状态复位回到彩条");

        //---- 5. 走到 END 再复位 ----
        rst_n = 1'b1;
        #100;
        click(2'd1);
        click(2'd2);
        rst_n = 1'b0;
        #100;
        if (screen !== 2'd0) begin
            $display("  FAIL: END 状态复位后 screen = %0d", screen);
            err_cnt = err_cnt + 1;
        end
        else $display("  PASS: END 状态复位回到彩条");

        #500;
        $display("==================================================");
        if (err_cnt == 0) $display(">>> ALL CHECKS PASSED <<<");
        else              $display(">>> %0d CHECK(S) FAILED <<<", err_cnt);
        $display("==================================================");
        $finish;
    end

endmodule
