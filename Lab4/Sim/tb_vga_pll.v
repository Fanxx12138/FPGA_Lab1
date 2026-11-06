`timescale 1ns / 1ps
//=============================================================================
// tb_vga_pll.v  --  验证 50 MHz -> 25 MHz 二分频
//   期望：vga_clk 周期 = 40 ns（25 MHz），占空比 50%
//=============================================================================
module tb_vga_pll;

    reg  sys_clk;
    reg  sys_rst_n;
    wire vga_clk;

    // 50 MHz = 20 ns 周期
    initial sys_clk = 1'b0;
    always #10 sys_clk = ~sys_clk;

    vga_pll u_vga_pll (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .vga_clk   (vga_clk)
    );

    time t_rise, t_fall, t_prev_rise;
    time period, high_time;
    integer rise_cnt;

    initial begin
        $timeformat(-9, 0, " ns", 12);
        $dumpfile("tb_vga_pll.vcd");
        $dumpvars(0, tb_vga_pll);

        sys_rst_n  = 1'b0;
        rise_cnt   = 0;
        t_prev_rise = 0;

        #100;
        sys_rst_n = 1'b1;

        // 观察 5 个上升沿
        repeat (10) @(posedge vga_clk);
        #100;

        $display("--------------------------------------------------");
        $display("vga_clk period   = %0t   (expect 40 ns)", period);
        $display("vga_clk high     = %0t   (expect 20 ns)", high_time);
        if (period == 40 && high_time == 20)
            $display("PASS: vga_pll 二分频正确");
        else
            $display("FAIL: vga_pll 分频错误");
        $display("--------------------------------------------------");
        $finish;
    end

    // 测量周期与高电平宽度
    always @(posedge vga_clk) begin
        t_rise = $time;
        if (rise_cnt > 0) period = t_rise - t_prev_rise;
        t_prev_rise = t_rise;
        rise_cnt = rise_cnt + 1;
    end

    always @(negedge vga_clk)
        high_time = $time - t_rise;

endmodule
