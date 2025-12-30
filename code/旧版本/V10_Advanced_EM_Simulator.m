function Advanced_EM_Simulator()
    %% 高级电磁波与传输线仿真系统 (Advanced EM Wave Simulator) v10 Final Fix
    % --- 修复日志 (v10) ---
    % 1. 初始化修复：程序启动时强制刷新视图可见性，解决史密斯圆图背景错误显示在 2D 界面上的问题。
    % 2. 稳定性增强：优化了视图切换的逻辑，确保所有子对象（Sub-objects）都能正确隐藏/显示。
    
    % --- 颜色主题 (Dark Sci-Fi) ---
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
    params.f     = 1e9;           
    params.Z0    = 50;           
    params.RL    = 50;           
    params.XL    = -50;          
    params.Alpha = 0;         
    
    % --- 创建主图形窗口 ---
    hFig = figure('Name', '电磁场课程设计：多维传输线综合分析平台 v10', ...
                  'NumberTitle', 'off', ...
                  'Color', theme.bg, ...
                  'Position', [50, 50, 1280, 760], ...
                  'MenuBar', 'none', ...
                  'ToolBar', 'figure', ...
                  'InvertHardcopy', 'off', ...
                  'Renderer', 'opengl'); 

    try
        %% --- UI 布局管理 (使用 Normalized 单位自适应) ---
        
        % 0. 顶部标题栏
        uicontrol('Parent', hFig, 'Style', 'text', 'String', 'ADVANCED EM LAB - 电磁场与波虚拟仿真平台', ...
                  'Units', 'normalized', 'Position', [0 0.94 1 0.06], ...
                  'FontSize', 16, 'FontWeight', 'bold', ...
                  'ForegroundColor', theme.cyan, 'BackgroundColor', theme.panel_bg);
    
        % 1. 顶部视图切换栏
        btn_group = uibuttongroup('Parent', hFig, ...
                                  'Units', 'normalized', 'Position', [0.01 0.87 0.25 0.06], ...
                                  'Title', '', 'BackgroundColor', theme.panel_bg, ...
                                  'SelectionChangedFcn', @on_view_change, ...
                                  'BorderType', 'none');
        
        uicontrol(btn_group, 'Style', 'text', 'String', '视图模式 / VIEW MODE', ...
                  'Units', 'normalized', 'Position', [0.02 0.4 0.35 0.4], ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'FontSize', 9);
    
        create_styled_radio(btn_group, [0.38 0.1 0.18 0.8], '2D', '2D', theme);
        create_styled_radio(btn_group, [0.58 0.1 0.18 0.8], '3D', '3D', theme);
        create_styled_radio(btn_group, [0.78 0.1 0.20 0.8], 'Smith', 'Smith', theme);
    
        % 2. 左侧参数控制面板
        panel_ctrl = uipanel('Parent', hFig, 'Title', '', ...
                             'Units', 'normalized', 'Position', [0.01 0.02 0.25 0.84], ...
                             'BackgroundColor', theme.panel_bg, 'BorderType', 'none');
        
        uicontrol(panel_ctrl, 'Style', 'text', 'String', '参数控制 / PARAMETERS', ...
                  'Units', 'normalized', 'Position', [0.05 0.92 0.9 0.05], ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'FontSize', 11);
    
        create_param_control(panel_ctrl, 0.82, '负载电阻 RL (Ω)', params.RL, 0, 200, @(v)update_val('RL',v), theme);
        create_param_control(panel_ctrl, 0.70, '负载电抗 XL (Ω)', params.XL, -200, 200, @(v)update_val('XL',v), theme);
        create_param_control(panel_ctrl, 0.58, '特性阻抗 Z0 (Ω)', params.Z0, 10, 100, @(v)update_val('Z0',v), theme);
        create_param_control(panel_ctrl, 0.46, '衰减常数 α (Np/m)', params.Alpha, 0, 0.5, @(v)update_val('Alpha',v), theme);
    
        uicontrol(panel_ctrl, 'Style', 'text', ...
                  'Units', 'normalized', 'Position', [0.05 0.35 0.9 0.04], ...
                  'String', '实时指标 / REAL-TIME DATA', 'FontWeight', 'bold', ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left');
              
        info_box = uicontrol(panel_ctrl, 'Style', 'edit', 'Max', 2, ...
                             'Units', 'normalized', 'Position', [0.05 0.02 0.9 0.32], ...
                             'String', 'System initializing...', 'FontSize', 10, 'FontName', 'Consolas', ...
                             'HorizontalAlignment', 'left', 'Enable', 'inactive', ...
                             'BackgroundColor', theme.bg, 'ForegroundColor', theme.cyan);
    
        % 3. 创建坐标轴
        % 2D Upper Plot
        ax_2d_wave = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.56 0.66 0.32], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', '2D', 'Visible', 'on');
        grid(ax_2d_wave, 'on'); hold(ax_2d_wave, 'on');
        title(ax_2d_wave, 'Voltage & Current Distributions', 'Color', theme.text);
        
        % 2D Lower Plot
        ax_2d_imp = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.10 0.66 0.32], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', '2D', 'Visible', 'on');
        grid(ax_2d_imp, 'on'); hold(ax_2d_imp, 'on');
        title(ax_2d_imp, 'Impedance Magnitude |Z(z)|', 'Color', theme.text);
        
        % 3D Plot
        ax_3d = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.10 0.66 0.80], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'ZColor', theme.text, ...
            'Tag', '3D', 'Visible', 'off');
        grid(ax_3d, 'on'); hold(ax_3d, 'on');
        view(ax_3d, [-40, 25]); axis(ax_3d, 'tight');
        title(ax_3d, '3D Phasor Space (Helix)', 'Color', theme.text);
        
        % Smith Plot
        ax_smith = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.35 0.10 0.56 0.78], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', 'Smith', 'Visible', 'off');
        axis(ax_smith, 'equal'); axis(ax_smith, 'off'); hold(ax_smith, 'on');
    
        %% --- 图形对象初始化 ---
        set(info_box, 'String', 'Generating Graphics Objects...'); drawnow;
        H = init_graphics_objects();
        
        % [FIXED] 初始化完成后，强制调用一次视图刷新，确保 Smith Chart 初始隐藏
        refresh_view_visibility('2D');
        
        set(info_box, 'String', 'System Ready.'); drawnow;

        % --- 启动仿真循环 ---
        c = 3e8;
        t = 0;
        dt = 1 / params.f / 150; 
        
        view_mode = '2D'; 
        
        t_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.05, 'TimerFcn', @animation_loop);
        start(t_timer);
        set(hFig, 'CloseRequestFcn', @close_gui);
        
    catch ME
        errordlg(sprintf('Initialization Failed:\n%s', ME.message), 'Error');
        delete(hFig);
    end

    %% --- 核心逻辑 ---

    function close_gui(~, ~)
        try stop(t_timer); delete(t_timer); catch; end
        delete(hFig);
    end

    function update_val(name, val)
        params.(name) = val;
    end

    function on_view_change(~, event)
        view_mode = event.NewValue.Tag;
        refresh_view_visibility(view_mode);
    end

    % [新增] 独立的视图刷新函数，供初始化和切换时调用
    function refresh_view_visibility(mode)
        % 1. 先全部隐藏
        set_visible(ax_2d_wave, 'off');
        set_visible(ax_2d_imp, 'off');
        set_visible(ax_3d, 'off');
        set_visible(ax_smith, 'off');
        
        % 2. 显示指定视图
        switch mode
            case '2D'
                set_visible(ax_2d_wave, 'on');
                set_visible(ax_2d_imp, 'on');
            case '3D'
                set_visible(ax_3d, 'on');
            case 'Smith'
                set_visible(ax_smith, 'on');
        end
        
        function set_visible(ax, state)
            set(ax, 'Visible', state);
            % 关键：必须设置所有 Children 的 Visible 属性
            % 因为 plot() 创建的对象可能默认是 visible 'on'，即使 Axes 是 'off'
            ch = get(ax, 'Children');
            set(ch, 'Visible', state);
        end
    end

    function animation_loop(~, ~)
        try
            if ~isvalid(hFig), return; end
            
            % --- 1. 物理计算 ---
            lambda = c / params.f;
            w = 2 * pi * params.f;
            beta = 2 * pi / lambda;
            gamma_prop = params.Alpha + 1j * beta;
            Z_L = params.RL + 1j * params.XL;
            Gamma_L = (Z_L - params.Z0) / (Z_L + params.Z0);
            if isnan(Gamma_L), Gamma_L = 0; end
            
            z_len = 2.0 * lambda; 
            z = linspace(-z_len, 0, 400); 
            
            V0_plus = 1; 
            exp_pos = exp(gamma_prop * z);
            exp_neg = exp(-gamma_prop * z);
            time_phasor = exp(1j * w * t);
            
            V_inc_c = V0_plus * exp_neg .* time_phasor;
            V_ref_c = V0_plus * Gamma_L * exp_pos .* time_phasor;
            V_tot_c = V_inc_c + V_ref_c;
            
            I_tot_c = (V0_plus / params.Z0) * (exp_neg - Gamma_L * exp_pos) .* time_phasor;
            Z_dist = V_tot_c ./ I_tot_c;
            
            vswr = (1 + abs(Gamma_L))/(1 - abs(Gamma_L));
            if vswr > 100, vswr = 100; end 
            rl_dB = -20*log10(abs(Gamma_L)+eps);

            % --- 2. 图形更新 ---
            switch view_mode
                case '2D'
                    set(H.v_env_up, 'XData', z/lambda, 'YData', abs(V_tot_c));
                    set(H.v_env_dn, 'XData', z/lambda, 'YData', -abs(V_tot_c));
                    set(H.v_line,   'XData', z/lambda, 'YData', real(V_tot_c));
                    set(H.i_line,   'XData', z/lambda, 'YData', real(I_tot_c)*params.Z0);
                    title(ax_2d_wave, sprintf('Voltage & Current (VSWR=%.2f)', vswr));
                    
                    set(H.z_line,   'XData', z/lambda, 'YData', abs(Z_dist));
                    set(H.z0_line,  'XData', [min(z/lambda) 0], 'YData', [params.Z0 params.Z0]); 
                    
                case '3D'
                    set(H.h3_tot, 'XData', z/lambda, 'YData', real(V_tot_c), 'ZData', imag(V_tot_c));
                    set(H.h3_inc, 'XData', z/lambda, 'YData', real(V_inc_c), 'ZData', imag(V_inc_c));
                    set(H.h3_ref, 'XData', z/lambda, 'YData', real(V_ref_c), 'ZData', imag(V_ref_c));
                    
                    v_inc_0 = V_inc_c(end); 
                    set(H.q3_inc, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_inc_0), 'WData', imag(v_inc_0));
                    
                    v_ref_0 = V_ref_c(end);
                    set(H.q3_ref, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_ref_0), 'WData', imag(v_ref_0));
                                  
                    v_tot_0 = V_tot_c(end);
                    set(H.q3_tot, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_tot_0), 'WData', imag(v_tot_0));

                case 'Smith'
                    theta = linspace(0, 2*pi, 100);
                    rho = abs(Gamma_L); if rho > 1, rho = 1; end
                    set(H.s_vswr, 'XData', rho*cos(theta), 'YData', rho*sin(theta));
                    set(H.s_dot,  'XData', real(Gamma_L),  'YData', imag(Gamma_L));
                    set(H.s_txt1, 'String', sprintf('VSWR Circle = %.2f', vswr));
            end
            
            update_info_panel(Gamma_L, vswr, rl_dB);
            
            t = t + dt;
            drawnow limitrate; 
            
        catch ME
            set(hFig, 'Name', ['Error: ' ME.message]);
        end
    end

    %% --- 图形初始化函数 ---
    function H = init_graphics_objects()
        % 1. Init 2D
        H.v_env_up = plot(ax_2d_wave, NaN, NaN, 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        H.v_env_dn = plot(ax_2d_wave, NaN, NaN, 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        H.v_line   = plot(ax_2d_wave, NaN, NaN, 'Color', theme.cyan, 'LineWidth', 2.5);
        H.i_line   = plot(ax_2d_wave, NaN, NaN, 'Color', theme.magenta, 'LineWidth', 1.5, 'LineStyle', '-.');
        legend(ax_2d_wave, {'Envelope', '', 'Voltage', 'Current'}, 'Location', 'northwest', 'TextColor', theme.text, 'Color', theme.panel_bg, 'EdgeColor', 'none');
        ylim(ax_2d_wave, [-2.5 2.5]);
        
        H.z_line   = plot(ax_2d_imp, NaN, NaN, 'Color', theme.yellow, 'LineWidth', 2);
        H.z0_line  = line([0 0], [50 50], 'Parent', ax_2d_imp, 'Color', theme.green, 'LineStyle', '--');
        ylim(ax_2d_imp, [0, 200]);
        
        % 2. Init 3D
        H.h3_tot = plot3(ax_3d, NaN, NaN, NaN, 'Color', [1 1 1], 'LineWidth', 3);
        H.h3_inc = plot3(ax_3d, NaN, NaN, NaN, 'Color', theme.cyan, 'LineWidth', 1.5);
        H.h3_ref = plot3(ax_3d, NaN, NaN, NaN, 'Color', theme.magenta, 'LineWidth', 1.5);
        
        H.q3_tot = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', [1 1 1], 'LineWidth', 4, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
        H.q3_inc = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', theme.cyan, 'LineWidth', 2, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
        H.q3_ref = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', theme.magenta, 'LineWidth', 2, 'MaxHeadSize', 0.5, 'AutoScale', 'off');

        zlim(ax_3d, [-2 2]); ylim(ax_3d, [-2 2]);
        xlabel(ax_3d, 'z (\lambda)'); ylabel(ax_3d, 'Real'); zlabel(ax_3d, 'Imag');
        
        % 3. Init Smith
        smith_data = prepare_smith_chart();
        for i = 1:length(smith_data.r_circles)
            c = smith_data.r_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        for i = 1:length(smith_data.x_circles)
            c = smith_data.x_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        plot(ax_smith, [-1 1], [0 0], 'Color', [0.5 0.5 0.5]);
        
        H.s_vswr = plot(ax_smith, NaN, NaN, 'Color', theme.green, 'LineWidth', 2, 'LineStyle', '--');
        H.s_dot  = plot(ax_smith, NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', theme.magenta, 'MarkerEdgeColor', 'w');
        
        text(0, 1.2, 'Smith Chart', 'Parent', ax_smith, 'Color', theme.text, 'FontSize', 14, 'HorizontalAlignment', 'center');
        H.s_txt1 = text(0, -1.2, '', 'Parent', ax_smith, 'Color', theme.green, 'HorizontalAlignment', 'center', 'FontSize', 12);
    end

    function update_info_panel(Gamma, vswr, rl)
        str = {
            '---------------------------';
            ' STATUS MONITOR';
            '---------------------------';
            ' [KEY METRICS]';
            sprintf(' VSWR       : %.3f', vswr);
            sprintf(' Gamma Mag  : %.3f', abs(Gamma));
            sprintf(' Gamma Ang  : %.1f deg', rad2deg(angle(Gamma)));
            sprintf(' Return Loss: %.1f dB', rl);
            ' ';
            ' [PARAMETERS]';
            sprintf(' Z0 (Char)  : %.1f Ohm', params.Z0);
            sprintf(' RL (Load)  : %.1f Ohm', params.RL);
            sprintf(' XL (Load)  : %+.1f j', params.XL);
            sprintf(' Alpha      : %.3f Np/m', params.Alpha);
        };
        set(info_box, 'String', str);
    end

    %% --- 辅助工具函数 ---
    
    function create_styled_radio(parent, pos, str, tag, th)
        uicontrol(parent, 'Style', 'radiobutton', 'String', str, ...
            'Units', 'normalized', 'Position', pos, ...
            'Tag', tag, 'BackgroundColor', th.panel_bg, ...
            'ForegroundColor', th.text, 'FontSize', 10);
    end

    function create_param_control(parent, y_pos, label, val_init, min_v, max_v, callback, th)
        uicontrol(parent, 'Style', 'text', ...
            'Units', 'normalized', 'Position', [0.05 y_pos 0.9 0.04], ...
            'String', label, 'HorizontalAlignment', 'left', ...
            'BackgroundColor', th.panel_bg, 'ForegroundColor', th.text_dim, 'FontSize', 10);
        
        sld = uicontrol(parent, 'Style', 'slider', ...
            'Units', 'normalized', 'Position', [0.05 y_pos-0.05 0.65 0.04], ...
            'Min', min_v, 'Max', max_v, 'Value', val_init, 'BackgroundColor', th.bg);
        
        ed = uicontrol(parent, 'Style', 'edit', ...
            'Units', 'normalized', 'Position', [0.75 y_pos-0.05 0.20 0.04], ...
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