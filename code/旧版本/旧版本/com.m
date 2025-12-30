%% 题目7：驻波原理及其实验研究 - 动态计算机仿真
% 该程序模拟传输线上的电压驻波形成过程
% 对应研修报告中“方法应用示例”部分

clear; close all; clc;

%% 1. 参数设置 (可在此处修改以模拟不同实验条件)
f = 1e9;            % 频率: 1 GHz
c = 3e8;            % 光速
lambda = c / f;     % 波长
w = 2 * pi * f;     % 角频率
beta = 2 * pi / lambda; % 相位常数

Z0 = 50;            % 特性阻抗 (欧姆)
ZL = 50 + 1j*(-50);   % 负载阻抗 (欧姆) -> 尝试修改为 50, 0, inf, 或 complex

% 传输线长度 (显示 3 个波长)
z_len = 3 * lambda; 
z = linspace(-z_len, 0, 1000); % z轴坐标 (负载位于 z=0)

%% 2. 理论计算 (对应“方法论述”部分)
% 计算反射系数 Gamma
Gamma = (ZL - Z0) / (ZL + Z0);

% 计算驻波比 VSWR
VSWR = (1 + abs(Gamma)) / (1 - abs(Gamma));

% 计算入射波与反射波幅值 (假设入射波幅值为 1V)
V_inc_amp = 1;
V_ref_amp = V_inc_amp * abs(Gamma);

fprintf('--- 仿真结果 ---\n');
fprintf('负载阻抗 ZL = %.2f %+.2fj Ohm\n', real(ZL), imag(ZL));
fprintf('反射系数 Gamma = %.4f angle %.2f deg\n', abs(Gamma), rad2deg(angle(Gamma)));
fprintf('驻波比 VSWR  = %.4f\n', VSWR);

%% 3. 动态仿真循环
figure('Color', 'w', 'Position', [100, 100, 1000, 600]);

% 预先计算包络线 (驻波最大值和最小值)
V_max = V_inc_amp * (1 + abs(Gamma));
V_min = V_inc_amp * (1 - abs(Gamma));
Envelope_Max = V_inc_amp * abs(1 + Gamma .* exp(2j * beta * z)); % 严格包络理论值

% 动画循环参数
t_end = 4 / f;      % 模拟 4 个周期
dt = t_end / 200;   % 时间步长
time_steps = 0:dt:t_end;

for t = time_steps
    % --- 核心物理公式 ---
    % 入射波 (向 +z 方向传播)
    V_inc = V_inc_amp * exp(-1j * beta * z) * exp(1j * w * t);
    
    % 反射波 (向 -z 方向传播，考虑反射系数的幅度和相位)
    V_ref = V_inc_amp * Gamma * exp(1j * beta * z) * exp(1j * w * t);
    
    % 合成波 (驻波)
    V_total = V_inc + V_ref;
    
    % --- 绘图 ---
    clf;
    hold on; box on; grid on;
    
    % 1. 绘制包络线 (虚线)
    plot(z/lambda, abs(Envelope_Max), 'g--', 'LineWidth', 2, 'DisplayName', '驻波包络 (Envelope)');
    plot(z/lambda, -abs(Envelope_Max), 'g--', 'LineWidth', 2, 'HandleVisibility', 'off');
    
    % 2. 绘制瞬时波形
    plot(z/lambda, real(V_inc), 'b', 'LineWidth', 1.5, 'DisplayName', '入射波 (Incident)');
    plot(z/lambda, real(V_ref), 'r', 'LineWidth', 1.5, 'DisplayName', '反射波 (Reflected)');
    plot(z/lambda, real(V_total), 'k', 'LineWidth', 3, 'DisplayName', '合成驻波 (Total)');
    
    % 3. 图形美化
    xlabel('距离 (z / \lambda)', 'FontSize', 12);
    ylabel('电压幅值 (V)', 'FontSize', 12);
    title(sprintf('驻波仿真 (ZL=%.0f%+.0fj, VSWR=%.2f)', real(ZL), imag(ZL), VSWR), 'FontSize', 14);
    legend('Location', 'northeastoutside', 'FontSize', 10);
    axis([-3 0 -2.5 2.5]); % 固定坐标轴范围
    
    % 绘制负载位置
    xline(0, 'k-', 'Load (z=0)', 'LabelVerticalAlignment', 'bottom');
    
    drawnow;
end