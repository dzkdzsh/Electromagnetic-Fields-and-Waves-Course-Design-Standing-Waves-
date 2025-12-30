function Advanced_EM_Simulator()
    %% 高级电磁波与传输线仿真系统 (Advanced EM Wave Simulator)
    % 功能：
    % 1. 交互式调节负载阻抗、特性阻抗、频率及衰减因子
    % 2. 实时动态展示电压(V)与电流(I)的驻波形态
    % 3. 展示沿线阻抗分布 |Z(z)|
    % 4. 实时计算工程指标：VSWR, Gamma, Return Loss, Power
    %
    % 使用方法：直接运行此函数，在弹出的窗口中操作滑块即可。

    % --- 初始化参数 ---
    f_init = 1e9;           % 初始频率 1GHz
    Z0_init = 50;           % 初始特性阻抗 50 Ohm
    RL_init = 50;           % 初始负载电阻 50 Ohm
    XL_init = -50;          % 初始负载电抗 -50 Ohm
    alpha_init = 0;         % 初始衰减常数 (Np/m)
    
    % --- 创建主图形窗口 ---
    hFig = figure('Name', '电磁场课程设计：高级传输线仿真实验室', ...
                  'NumberTitle', 'off', ...
                  'Color', [0.95 0.95 0.95], ...
                  'Position', [100, 100, 1200, 700], ...
                  'MenuBar', 'none', ...
                  'ToolBar', 'figure');

    % --- UI 控件布局 (左侧控制面板) ---
    panel_ctrl = uipanel('Parent', hFig, 'Title', '实验参数控制台', ...
                         'FontSize', 11, 'FontWeight', 'bold', ...
                         'Position', [0.01 0.01 0.25 0.98], ...
                         'BackgroundColor', [0.9 0.9 0.9]);

    % 1. 负载电阻 RL
    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [20 620 200 20], ...
              'String', '负载电阻 R_L (Ω)', 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);
    sld_RL = uicontrol(panel_ctrl, 'Style', 'slider', 'Position', [20 600 200 20], ...
                       'Min', 0, 'Max', 200, 'Value', RL_init, 'Callback', @update_simulation);
    txt_RL = uicontrol(panel_ctrl, 'Style', 'text', 'Position', [230 600 50 20], ...
                       'String', num2str(RL_init), 'BackgroundColor', [0.9 0.9 0.9]);

    % 2. 负载电抗 XL
    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [20 560 200 20], ...
              'String', '负载电抗 X_L (Ω)', 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);
    sld_XL = uicontrol(panel_ctrl, 'Style', 'slider', 'Position', [20 540 200 20], ...
                       'Min', -200, 'Max', 200, 'Value', XL_init, 'Callback', @update_simulation);
    txt_XL = uicontrol(panel_ctrl, 'Style', 'text', 'Position', [230 540 50 20], ...
                       'String', num2str(XL_init), 'BackgroundColor', [0.9 0.9 0.9]);

    % 3. 特性阻抗 Z0
    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [20 500 200 20], ...
              'String', '特性阻抗 Z_0 (Ω)', 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);
    sld_Z0 = uicontrol(panel_ctrl, 'Style', 'slider', 'Position', [20 480 200 20], ...
                       'Min', 10, 'Max', 100, 'Value', Z0_init, 'Callback', @update_simulation);
    txt_Z0 = uicontrol(panel_ctrl, 'Style', 'text', 'Position', [230 480 50 20], ...
                       'String', num2str(Z0_init), 'BackgroundColor', [0.9 0.9 0.9]);

    % 4. 衰减常数 Alpha (有耗传输线)
    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [20 440 200 20], ...
              'String', '衰减常数 \alpha (Np/m)', 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);
    sld_Alpha = uicontrol(panel_ctrl, 'Style', 'slider', 'Position', [20 420 200 20], ...
                          'Min', 0, 'Max', 0.5, 'Value', alpha_init, 'Callback', @update_simulation);
    txt_Alpha = uicontrol(panel_ctrl, 'Style', 'text', 'Position', [230 420 50 20], ...
                          'String', num2str(alpha_init), 'BackgroundColor', [0.9 0.9 0.9]);
    
    % 5. 信息显示区
    info_box = uicontrol(panel_ctrl, 'Style', 'edit', 'Max', 2, 'Position', [20 50 260 250], ...
                         'String', '初始化中...', 'FontSize', 10, ...
                         'HorizontalAlignment', 'left', 'Enable', 'inactive', ...
                         'BackgroundColor', [1 1 1]);
    
    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [20 310 200 20], ...
              'String', '实时参数测量:', 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);


    % --- 绘图区域布局 ---
    % 上方：电压/电流驻波动画
    ax_wave = axes('Parent', hFig, 'Position', [0.32 0.55 0.65 0.40]);
    grid(ax_wave, 'on'); box(ax_wave, 'on');
    xlabel(ax_wave, '距离 Load 的位置 (m)'); ylabel(ax_wave, '归一化幅值');
    title(ax_wave, '电压 V(z,t) 与 电流 I(z,t) 动态驻波分布');

    % 下方：阻抗幅度分布
    ax_imp = axes('Parent', hFig, 'Position', [0.32 0.10 0.65 0.35]);
    grid(ax_imp, 'on'); box(ax_imp, 'on');
    xlabel(ax_imp, '距离 Load 的位置 (m)'); ylabel(ax_imp, '阻抗模值 |Z(z)| (\Omega)');
    title(ax_imp, '沿线阻抗变换特性 |Z(z)|');

    % --- 仿真核心变量初始化 ---
    c = 3e8;
    lambda = c / f_init;
    z_len = 2.5 * lambda; % 仿真长度 2.5 个波长
    z = linspace(-z_len, 0, 500); % 坐标轴：负载在 z=0, 源在左侧
    t = 0;
    dt = 1 / f_init / 40; % 时间步长

    % 启动定时器进行动画更新
    t_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.05, ...
                    'TimerFcn', @animation_loop);
    start(t_timer);

    % 当窗口关闭时停止定时器
    set(hFig, 'CloseRequestFcn', @close_gui);

    %% --- 回调函数与逻辑 ---

    function close_gui(~, ~)
        stop(t_timer);
        delete(t_timer);
        delete(hFig);
    end

    function update_simulation(~, ~)
        % 仅仅更新显示的数值，物理计算在动画循环中实时获取
        set(txt_RL, 'String', sprintf('%.1f', get(sld_RL, 'Value')));
        set(txt_XL, 'String', sprintf('%.1f', get(sld_XL, 'Value')));
        set(txt_Z0, 'String', sprintf('%.1f', get(sld_Z0, 'Value')));
        set(txt_Alpha, 'String', sprintf('%.3f', get(sld_Alpha, 'Value')));
    end

    function animation_loop(~, ~)
        try
            if ~isvalid(hFig), return; end
            
            % 1. 获取当前控件参数
            R_L = get(sld_RL, 'Value');
            X_L = get(sld_XL, 'Value');
            Z_0 = get(sld_Z0, 'Value');
            alpha = get(sld_Alpha, 'Value');
            
            Z_L = R_L + 1j * X_L;
            
            % 2. 物理量计算
            w = 2 * pi * f_init;
            beta = 2 * pi / lambda;
            gamma = alpha + 1j * beta; % 传播常数 (含衰减)
            
            % 反射系数 Gamma_L (负载处)
            Gamma_L = (Z_L - Z_0) / (Z_L + Z_0);
            
            % 驻波比 VSWR
            vswr_val = (1 + abs(Gamma_L)) / (1 - abs(Gamma_L));
            
            % 回波损耗 Return Loss (dB)
            if abs(Gamma_L) > 0
                rl_dB = -20 * log10(abs(Gamma_L));
            else
                rl_dB = Inf;
            end
            
            % 3. 核心波动方程 (传输线方程解)
            % 设入射波在 z=0 处(如果没有反射)的幅值为 1V
            V0_plus = 1; 
            
            % 电压 V(z,t) = V0+ * [ e^(-gamma*z) + Gamma_L * e^(+gamma*z) ] * e^(jwt)
            % 注意：z 是负值，从 -L 到 0
            V_spatial = V0_plus * (exp(-gamma * z) + Gamma_L * exp(gamma * z));
            V_instant = real(V_spatial .* exp(1j * w * t));
            
            % 电流 I(z,t) = (V0+/Z0) * [ e^(-gamma*z) - Gamma_L * e^(+gamma*z) ] * e^(jwt)
            I_spatial = (V0_plus / Z_0) * (exp(-gamma * z) - Gamma_L * exp(gamma * z));
            I_instant = real(I_spatial .* exp(1j * w * t));
            
            % 阻抗分布 Z(z) = V(z) / I(z)
            Z_dist = V_spatial ./ I_spatial;
            
            % 包络线计算
            V_envelope_max = abs(V_spatial);
            I_envelope_max = abs(I_spatial) * Z_0; % 归一化显示电流以便对比
            
            % 4. 绘图 - 上图：电压与电流
            cla(ax_wave); hold(ax_wave, 'on');
            % 绘制电压包络
            plot(ax_wave, z, V_envelope_max, 'b--', 'LineWidth', 1);
            plot(ax_wave, z, -V_envelope_max, 'b--', 'LineWidth', 1);
            % 绘制电压瞬时波
            plot(ax_wave, z, V_instant, 'b-', 'LineWidth', 2, 'DisplayName', '电压 V(z,t)');
            
            % 绘制电流瞬时波 (乘以Z0以便在同一量级显示)
            plot(ax_wave, z, I_instant * Z_0, 'r-', 'LineWidth', 1.5, 'DisplayName', '电流 I(z,t) \times Z_0');
            
            legend(ax_wave, 'show', 'Location', 'northwest');
            title(ax_wave, sprintf('传输线驻波仿真 (VSWR=%.2f)', vswr_val));
            ylim(ax_wave, [-2.5 2.5]);
            
            % 标出负载位置
            xline(ax_wave, 0, 'k-', {'负载', 'Load'}, 'LabelVerticalAlignment', 'bottom');
            
            % 5. 绘图 - 下图：阻抗模值分布
            cla(ax_imp); hold(ax_imp, 'on');
            plot(ax_imp, z, abs(Z_dist), 'k-', 'LineWidth', 2);
            yline(ax_imp, Z_0, 'g--', '特性阻抗 Z_0');
            ylim(ax_imp, [0, max(200, max(abs(Z_dist))) * 1.1]);
            
            % 6. 更新信息面板
            info_str = {
                sprintf('--- 关键指标 ---');
                sprintf('反射系数 |\\Gamma|: %.3f', abs(Gamma_L));
                sprintf('反射相位 \\angle\\Gamma: %.1f^\\circ', rad2deg(angle(Gamma_L)));
                sprintf('驻波比 VSWR: %.2f', vswr_val);
                sprintf('回波损耗 RL: %.1f dB', rl_dB);
                sprintf(' ');
                sprintf('--- 负载状态 ---');
                sprintf('Z_L = %.1f %+.1fj \\Omega', R_L, X_L);
                sprintf('Z_0 = %.1f \\Omega', Z_0);
            };
            set(info_box, 'String', info_str);
            
            % 更新时间
            t = t + dt;
            drawnow limitrate;
            
        catch
            % 防止关闭窗口时报错
        end
    end
end