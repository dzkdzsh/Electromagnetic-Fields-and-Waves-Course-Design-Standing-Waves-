function Advanced_EM_Simulator()
    %% 高级电磁波与传输线仿真系统 (Advanced EM Wave Simulator) v5.0 Stable
    % --- 修复日志 v5.0 ---
    % 1. 修复：CloseRequestFcn 中逻辑运算符使用错误导致的关闭报错。
    % 2. 修复：Smith 圆图中 line 指令在部分 MATLAB 版本中无法识别句柄的问题。
    % 3. 优化：图例 (Legend) 生成逻辑，避免在循环中重复创建导致的性能下降。
    
    % --- 颜色主题定义 (Dark Sci-Fi Theme) ---
    theme.bg        = [0.10 0.10 0.12]; 
    theme.panel_bg  = [0.16 0.16 0.18]; 
    theme.text      = [0.90 0.90 0.90]; 
    theme.text_dim  = [0.70 0.70 0.70]; 
    theme.cyan      = [0.00 0.85 1.00]; 
    theme.magenta   = [1.00 0.20 0.60]; 
    theme.green     = [0.20 1.00 0.40]; 
    theme.yellow    = [1.00 0.80 0.20]; 
    theme.grid      = [0.25 0.25 0.28]; 

    % --- 初始化参数 ---
    f_init = 1e9;           
    Z0_init = 50;           
    RL_init = 50;           
    XL_init = -50;          
    alpha_init = 0;         
    
    % --- 创建主图形窗口 ---
    hFig = figure('Name', '电磁场课程设计：多维传输线综合分析平台', ...
                  'NumberTitle', 'off', ...
                  'Color', theme.bg, ...
                  'Position', [50, 50, 1280, 760], ...
                  'MenuBar', 'none', ...
                  'ToolBar', 'figure', ...
                  'InvertHardcopy', 'off'); 

    %% --- UI 布局管理 ---
    
    % 0. 顶部标题栏
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'ADVANCED EM LAB - 电磁场与波虚拟仿真平台', ...
              'Position', [0 720 1280 40], 'FontSize', 16, 'FontWeight', 'bold', ...
              'ForegroundColor', theme.cyan, 'BackgroundColor', theme.panel_bg);

    % 1. 顶部视图切换栏
    btn_group = uibuttongroup('Parent', hFig, 'Position', [0.01 0.90 0.25 0.08], ...
                              'Title', '', 'BackgroundColor', theme.panel_bg, ...
                              'SelectionChangedFcn', @on_view_change, ...
                              'BorderType', 'none');
    
    uicontrol(btn_group, 'Style', 'text', 'String', 'VISUAL MODE / 视图模式', ...
              'Position', [10 35 200 15], 'ForegroundColor', theme.green, ...
              'BackgroundColor', theme.panel_bg, 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

    create_styled_radio(btn_group, [10 5 90 25], '2D 波形', '2D', theme);
    create_styled_radio(btn_group, [110 5 90 25], '3D 矢量', '3D', theme);
    create_styled_radio(btn_group, [210 5 90 25], 'Smith 圆图', 'Smith', theme);

    % 2. 左侧参数控制面板
    panel_ctrl = uipanel('Parent', hFig, 'Title', '', ...
                         'Position', [0.01 0.02 0.25 0.87], ...
                         'BackgroundColor', theme.panel_bg, 'BorderType', 'none');
    
    uicontrol(panel_ctrl, 'Style', 'text', 'String', 'PARAMETER CONTROL / 参数控制', ...
              'Position', [10 600 250 20], 'ForegroundColor', theme.green, ...
              'BackgroundColor', theme.panel_bg, 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

    create_param_control(panel_ctrl, 560, '负载电阻 R_L (Ω)', RL_init, 0, 200, @(v)update_val('RL',v), theme);
    create_param_control(panel_ctrl, 490, '负载电抗 X_L (Ω)', XL_init, -200, 200, @(v)update_val('XL',v), theme);
    create_param_control(panel_ctrl, 420, '特性阻抗 Z_0 (Ω)', Z0_init, 10, 100, @(v)update_val('Z0',v), theme);
    create_param_control(panel_ctrl, 350, '衰减常数 \alpha (Np/m)', alpha_init, 0, 0.5, @(v)update_val('Alpha',v), theme);

    uicontrol(panel_ctrl, 'Style', 'text', 'Position', [10 260 200 20], ...
              'String', 'REAL-TIME DATA / 实时指标', 'FontWeight', 'bold', ...
              'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
              'HorizontalAlignment', 'left');
          
    info_box = uicontrol(panel_ctrl, 'Style', 'edit', 'Max', 2, 'Position', [10 10 300 240], ...
                         'String', '初始化中...', 'FontSize', 11, 'FontName', 'Consolas', ...
                         'HorizontalAlignment', 'left', 'Enable', 'inactive', ...
                         'BackgroundColor', theme.bg, 'ForegroundColor', theme.cyan);

    % 3. 绘图区域
    ax_2d_wave = axes('Parent', hFig, 'Position', [0.32 0.58 0.65 0.35], 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', 'ax_2d');
    ax_2d_imp  = axes('Parent', hFig, 'Position', [0.32 0.10 0.65 0.35], 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', 'ax_2d');
    
    ax_3d = axes('Parent', hFig, 'Position', [0.32 0.10 0.65 0.82], 'Visible', 'off', ...
                 'Projection', 'perspective', 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'ZColor', theme.text, 'Tag', 'ax_3d');
    
    ax_smith = axes('Parent', hFig, 'Position', [0.40 0.15 0.50 0.75], 'Visible', 'off', ...
                    'DataAspectRatio', [1 1 1], 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', 'ax_smith');

    %% --- 全局状态变量 ---
    params = struct('RL', RL_init, 'XL', XL_init, 'Z0', Z0_init, 'Alpha', alpha_init);
    view_mode = '2D'; 
    smith_background_data = prepare_smith_chart();

    % --- 启动仿真循环 ---
    c = 3e8;
    t = 0;
    dt = 1 / f_init / 40;
    
    t_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.05, 'TimerFcn', @animation_loop);
    start(t_timer);
    
    % [FIXED] 使用专用的关闭函数，避免 lambda 表达式报错
    set(hFig, 'CloseRequestFcn', @close_gui);

    %% --- 核心逻辑 ---

    function close_gui(~, ~)
        % 安全关闭顺序：先停止计时器，再删除计时器，最后删除图形窗口
        try
            if strcmp(t_timer.Running, 'on')
                stop(t_timer);
            end
            delete(t_timer);
        catch
            % 忽略计时器删除错误
        end
        delete(hFig);
    end

    function update_val(name, val)
        params.(name) = val;
    end

    function on_view_change(~, event)
        view_mode = event.NewValue.Tag;
        % 重置所有视图
        set([ax_2d_wave, ax_2d_imp], 'Visible', 'off'); 
        cla(ax_2d_wave); cla(ax_2d_imp); legend(ax_2d_wave, 'off');
        
        set(ax_3d, 'Visible', 'off'); cla(ax_3d); legend(ax_3d, 'off');
        set(ax_smith, 'Visible', 'off'); cla(ax_smith); 
        axis(ax_smith, 'off');

        switch view_mode
            case '2D'
                set([ax_2d_wave, ax_2d_imp], 'Visible', 'on');
                grid(ax_2d_wave, 'on'); grid(ax_2d_imp, 'on');
                ax_2d_wave.GridColor = theme.grid; ax_2d_imp.GridColor = theme.grid;
            case '3D'
                set(ax_3d, 'Visible', 'on'); 
                grid(ax_3d, 'on'); ax_3d.GridColor = theme.grid;
                view(ax_3d, [-30, 25]);
            case 'Smith'
                set(ax_smith, 'Visible', 'off'); % 轴本身不显示，只显示绘制内容
        end
    end

    function animation_loop(~, ~)
        try
            if ~isvalid(hFig), return; end
            
            % 1. 物理计算
            lambda = c / f_init;
            w = 2 * pi * f_init;
            beta = 2 * pi / lambda;
            gamma_prop = params.Alpha + 1j * beta;
            Z_L = params.RL + 1j * params.XL;
            Gamma_L = (Z_L - params.Z0) / (Z_L + params.Z0);
            
            z_len = 2.0 * lambda; 
            z = linspace(-z_len, 0, 400); 
            
            V0_plus = 1; 
            V_inc_complex = V0_plus * exp(-gamma_prop * z) * exp(1j * w * t);
            V_ref_complex = V0_plus * Gamma_L * exp(gamma_prop * z) * exp(1j * w * t);
            V_total_complex = V_inc_complex + V_ref_complex;
            
            I_total_complex = (V0_plus / params.Z0) * (exp(-gamma_prop * z) - Gamma_L * exp(gamma_prop * z)) * exp(1j * w * t);
            Z_dist = V_total_complex ./ I_total_complex;

            vswr = (1 + abs(Gamma_L))/(1 - abs(Gamma_L));
            rl_dB = -20*log10(abs(Gamma_L)+eps);

            % 2. 绘图分发
            switch view_mode
                case '2D'
                    draw_2d_view(z, V_total_complex, I_total_complex, Z_dist, vswr, lambda);
                case '3D'
                    draw_3d_view(z, V_inc_complex, V_ref_complex, V_total_complex, lambda);
                case 'Smith'
                    draw_smith_view(Gamma_L, vswr);
            end
            
            % 3. 更新信息板
            update_info_panel(Gamma_L, vswr, rl_dB);
            
            t = t + dt;
            drawnow limitrate;
        catch ME
            % 调试输出，防止崩溃后无信息
            fprintf('Animation Loop Error: %s\n', ME.message);
        end
    end

    %% --- 绘图子函数 (样式增强版) ---
    
    function draw_2d_view(z, V_c, I_c, Z_d, vswr, lam)
        % V/I 波形
        cla(ax_2d_wave); hold(ax_2d_wave, 'on');
        
        plot(ax_2d_wave, z/lam, abs(V_c), 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        plot(ax_2d_wave, z/lam, -abs(V_c), 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        plot(ax_2d_wave, z/lam, real(V_c), 'Color', theme.cyan, 'LineWidth', 2.5);
        plot(ax_2d_wave, z/lam, real(I_c)*params.Z0, 'Color', theme.magenta, 'LineWidth', 1.5, 'LineStyle', '-.');
        
        set(ax_2d_wave, 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'GridColor', theme.grid, 'GridAlpha', 0.5);
        title(ax_2d_wave, sprintf('Voltage & Current Standing Waves (VSWR=%.2f)', vswr), 'Color', theme.text, 'FontSize', 12);
        
        % [FIXED] 避免重复创建 Legend
        if isempty(ax_2d_wave.Legend)
             legend(ax_2d_wave, {'Envelope', '', 'Voltage (V)', 'Current (I*Z0)'}, 'Location', 'northwest', 'TextColor', theme.text, 'Color', theme.panel_bg, 'EdgeColor', 'none');
        end
        
        ylim(ax_2d_wave, [-2.5 2.5]);
        xlabel(ax_2d_wave, 'Distance z (\lambda)', 'Color', theme.text_dim);
        
        % 阻抗分布
        cla(ax_2d_imp); hold(ax_2d_imp, 'on');
        plot(ax_2d_imp, z/lam, abs(Z_d), 'Color', theme.yellow, 'LineWidth', 2);
        yline(ax_2d_imp, params.Z0, 'Color', theme.green, 'LineStyle', '--', 'Label', 'Z0');
        
        set(ax_2d_imp, 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'GridColor', theme.grid, 'GridAlpha', 0.5);
        title(ax_2d_imp, 'Impedance Magnitude |Z(z)|', 'Color', theme.text, 'FontSize', 12);
        xlabel(ax_2d_imp, 'Distance z (\lambda)', 'Color', theme.text_dim);
        ylim(ax_2d_imp, [0, 200]);
    end

    function draw_3d_view(z, V_inc, V_ref, V_tot, lam)
        cla(ax_3d); hold(ax_3d, 'on');
        
        plot3(ax_3d, z/lam, real(V_tot), imag(V_tot), 'Color', [1 1 1], 'LineWidth', 3);
        plot3(ax_3d, z/lam, real(V_inc), imag(V_inc), 'Color', [theme.cyan, 0.3], 'LineWidth', 1);
        plot3(ax_3d, z/lam, real(V_ref), imag(V_ref), 'Color', [theme.magenta, 0.3], 'LineWidth', 1);
        
        set(ax_3d, 'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'ZColor', theme.text, 'GridColor', theme.grid, 'GridAlpha', 0.4);
        xlabel(ax_3d, 'z (\lambda)'); ylabel(ax_3d, 'Real'); zlabel(ax_3d, 'Imag');
        title(ax_3d, '3D Complex Phasor Helix', 'Color', theme.cyan, 'FontSize', 14);
        view(ax_3d, [-40, 25]);
        zlim(ax_3d, [-2 2]); ylim(ax_3d, [-2 2]);
    end

    function draw_smith_view(Gamma, vswr)
        cla(ax_smith); hold(ax_smith, 'on');
        axis(ax_smith, 'equal'); axis(ax_smith, 'off');
        
        % 背景圆 (使用 plot 代替 line 以兼容所有版本)
        for i = 1:length(smith_background_data.r_circles)
            c = smith_background_data.r_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        for i = 1:length(smith_background_data.x_circles)
            c = smith_background_data.x_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        % [FIXED] 使用 plot 绘制水平线
        plot(ax_smith, [-1 1], [0 0], 'Color', [0.5 0.5 0.5]);
        
        % VSWR 圆
        theta = linspace(0, 2*pi, 100);
        rho = abs(Gamma); if rho > 1, rho = 1; end
        plot(ax_smith, rho*cos(theta), rho*sin(theta), 'Color', theme.green, 'LineWidth', 2, 'LineStyle', '--');
        
        % 负载点
        plot(ax_smith, real(Gamma), imag(Gamma), 'o', 'MarkerSize', 10, 'MarkerFaceColor', theme.magenta, 'MarkerEdgeColor', 'w');
        
        text(ax_smith, 0, 1.2, 'Smith Chart (Impedance)', 'Color', theme.text, 'FontSize', 14, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        text(ax_smith, 0, -1.2, sprintf('VSWR Circle = %.2f', vswr), 'Color', theme.green, 'HorizontalAlignment', 'center', 'FontSize', 12);
    end

    function update_info_panel(Gamma, vswr, rl)
        str = {
            '---------------------------';
            sprintf(' MODE: %s', view_mode);
            '---------------------------';
            ' [KEY METRICS]';
            sprintf(' VSWR       : %.3f', vswr);
            sprintf(' Gamma Mag  : %.3f', abs(Gamma));
            sprintf(' Gamma Ang  : %.1f deg', rad2deg(angle(Gamma)));
            sprintf(' Return Loss: %.1f dB', rl);
            ' ';
            ' [SYSTEM PARAMETERS]';
            sprintf(' Z0 (Char)  : %.1f Ohm', params.Z0);
            sprintf(' ZL (Load)  : %.1f %+.1fj', params.RL, params.XL);
            sprintf(' Alpha (Att): %.3f Np/m', params.Alpha);
        };
        set(info_box, 'String', str);
    end

    %% --- 辅助工具函数 ---
    
    function create_styled_radio(parent, pos, str, tag, th)
        uicontrol(parent, 'Style', 'radiobutton', 'String', str, ...
            'Position', pos, 'Tag', tag, 'BackgroundColor', th.panel_bg, ...
            'ForegroundColor', th.text, 'FontSize', 10);
    end

    function create_param_control(parent, y_pos, label, val_init, min_v, max_v, callback, th)
        uicontrol(parent, 'Style', 'text', 'Position', [20 y_pos 200 20], ...
            'String', label, 'HorizontalAlignment', 'left', ...
            'BackgroundColor', th.panel_bg, 'ForegroundColor', th.text_dim, 'FontSize', 10);
        
        sld = uicontrol(parent, 'Style', 'slider', 'Position', [20 y_pos-25 180 20], ...
            'Min', min_v, 'Max', max_v, 'Value', val_init, 'BackgroundColor', th.bg);
        
        ed = uicontrol(parent, 'Style', 'edit', 'Position', [210 y_pos-25 60 20], ...
            'String', num2str(val_init), 'BackgroundColor', [0.2 0.2 0.22], ...
            'ForegroundColor', th.cyan, 'FontSize', 10);
        
        set(sld, 'Callback', @(s,~) sync_ui(s, ed, callback));
        set(ed, 'Callback', @(e,~) sync_ui(e, sld, callback));
        
        function sync_ui(src, target, cb)
            val = get(src, 'Value');
            if strcmp(get(src, 'Style'), 'edit')
                val = str2double(get(src, 'String'));
                if val < min_v, val = min_v; elseif val > max_v, val = max_v; end
                if isnan(val), val = min_v; end
            end
            set(sld, 'Value', val);
            set(ed, 'String', num2str(val));
            cb(val);
        end
    end

    function data = prepare_smith_chart()
        data.r_circles = {};
        data.x_circles = {};
        
        r_vals = [0, 0.5, 1, 2, 5];
        t = linspace(0, 2*pi, 100);
        for k = 1:length(r_vals)
            r = r_vals(k);
            cx = r / (1+r); cy = 0; rad = 1 / (1+r);
            data.r_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
        end
        
        x_vals = [0.5, 1, 2];
        for k = 1:length(x_vals)
            x = x_vals(k);
            cx = 1; cy = 1/x; rad = 1/x;
            data.x_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
            cy = -1/x;
            data.x_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
        end
    end
end