%% 绘制 cmp 一位比较器测试台波形
%  数据来源: cmp_tb.vcd  --(vcd2csv .py)-->  cmp_tb.csv
%  用法: 在本目录下运行  plot_cmp_tb

clear; clc; close all;

csvFile = 'cmp_tb.csv';
outPng  = 'cmp_tb_waveform.png';

%% ---------- 要画的信号 ----------
%  第一列 = CSV 里的信号名, 第二列 = 图上显示的名字
%  行序 = 图上从上到下的顺序: 先输入后输出, 输入 A 在前, 输出低位在前
sigList = {
    'cmp_tb.B2',   'Act_key1'    % 输入 A
    'cmp_tb.B3',   'Act_key2'    % 输入 B
    'cmp_tb.led1', 'Act_led1'    % 输出 lt  (A<B)
    'cmp_tb.led2', 'Act_led2'    % 输出 eq  (A=B)
    'cmp_tb.led3', 'Act_led3'    % 输出 gt  (A>B)
};

%% ---------- 1. 读取 CSV ----------
T = readtable(csvFile, 'VariableNamingRule', 'preserve');
colNames = T.Properties.VariableNames;
t        = T{:, 1};

if isempty(sigList)
    sigNames = colNames(2:end);
    colIdx   = (2:numel(colNames))';
    labels   = sigNames;
else
    sigNames = sigList(:, 1);
    labels   = sigList(:, 2);
    colIdx   = zeros(numel(sigNames), 1);
    for i = 1:numel(sigNames)
        k = find(strcmp(colNames, sigNames{i}), 1);
        if isempty(k)
            error('CSV 里找不到信号: %s', sigNames{i});
        end
        colIdx(i) = k;
    end
end

data = T{:, colIdx};
if iscell(data) || ischar(data)
    data = str2double(data);        % 'x' -> NaN
end

%% ---------- 2. 末端补一点, 让最后状态成为一段波形 ----------
dt   = median(diff(t));
t    = [t; t(end) + dt];
data = [data; data(end, :)];

%% ---------- 3. 画阶梯波形 ----------
n  = numel(labels);
ax = gobjects(n, 1);

leftMargin  = 0.17;
rightMargin = 0.97;

figure('Color', 'w', 'Position', [80 80 980 max(430, 74 * n)]);

for k = 1:n
    ax(k) = subplot(n, 1, k);
    stairs(ax(k), t, data(:, k), 'LineWidth', 1.7, 'Color', [0.10 0.35 0.75]);

    ylim(ax(k), [-0.3 1.3]);
    yticks(ax(k), [0 1]);
    xlim(ax(k), [t(1) t(end)]);
    grid(ax(k), 'on');
    set(ax(k), 'XGrid', 'on', 'YGrid', 'off', ...
               'TickDir', 'out', 'Box', 'on', 'FontSize', 9);

    pos = get(ax(k), 'Position');
    set(ax(k), 'Position', [leftMargin, pos(2), rightMargin - leftMargin, pos(4)]);

    text(ax(k), -0.055, 0.5, labels{k}, 'Units', 'normalized', ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
         'Interpreter', 'none', 'FontSize', 11);

    if k < n
        set(ax(k), 'XTickLabel', []);
    else
        xlabel('时间 / ns', 'FontSize', 10);
    end
end

linkaxes(ax, 'x');
title(ax(1), 'cmp 一位数字比较器仿真波形', 'FontSize', 12, 'FontWeight', 'bold');

%% ---------- 4. 保存 ----------
exportgraphics(gcf, outPng, 'Resolution', 150);
fprintf('波形已保存: %s\n', outPng);
fprintf('共 %d 个信号, %d 个时间点\n', n, numel(t));
