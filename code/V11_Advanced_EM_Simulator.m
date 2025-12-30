function Advanced_EM_Simulator()
    %% 高级电磁波与传输线仿真系统 (Advanced EM Wave Simulator) v11 Real-Time Fix
    %
    % ========================================================================
    % 项目概述 (PROJECT OVERVIEW)
    % ========================================================================
    % 本程序是一个实时、交互式的电磁场与传输线综合仿真平台，用于教学和研究。
    % 核心功能：
    %   1. 传输线理论的可视化：显示电压、电流、阻抗沿传输线的分布
    %   2. 反射现象的实时演示：通过改变负载参数，观察反射系数、VSWR 等指标的变化
    %   3. 三种可视化模式：
    %      - 2D 模式：电压/电流曲线和阻抗分布（经典传输线图）
    %      - 3D 模式：在复平面上显示电压相量的螺旋轨迹（高级理解）
    %      - Smith 图：标准化阻抗平面，显示反射系数和 VSWR 圆（工程工具）
    %
    % ========================================================================
    % 核心物理原理 (PHYSICS FUNDAMENTALS)
    % ========================================================================
    % 传输线方程：
    %   V(z,t) = V+ exp(-γz) exp(jωt) + V- exp(+γz) exp(jωt)
    %   I(z,t) = (V+/Z0) exp(-γz) exp(jωt) - (V-/Z0) exp(+γz) exp(jωt)
    %
    % 其中：
    %   γ = α + jβ 是传播常数
    %     α：衰减常数（有损线）
    %     β：相位常数 = 2π/λ
    %   Z0：特性阻抗 = V/I（正向波）
    %   V+：正向（入射）波幅度
    %   V-：反向（反射）波幅度 = Γ_L × V+，其中 Γ_L 是负载反射系数
    %
    % 关键参数（Key Metrics）：
    %   反射系数：Γ = (Z_L - Z0) / (Z_L + Z0)
    %   VSWR = (1 + |Γ|) / (1 - |Γ|) - 衡量匹配程度
    %   回波损耗 (Return Loss) = -20 log10(|Γ|) dB
    %   阻抗：Z(z) = V(z) / I(z) - 随 z 变化（驻波效应）
    %
    % ========================================================================
    % 代码结构 (CODE STRUCTURE)
    % ========================================================================
    % 主函数流程：
    %   1. 初始化主窗口和 UI 控件
    %   2. 创建三个坐标轴（2D_wave, 2D_imp, 3D, Smith）
    %   3. 初始化图形对象（曲线、相量、网格）
    %   4. 启动定时器，执行实时仿真循环
    %
    % 核心仿真循环（animation_loop）：
    %   每 50 ms 执行一次，包含：
    %   a) 物理计算：根据当前参数计算波的分布和指标
    %   b) 图形更新：根据选择的视图模式刷新图形
    %   c) 时间步进：更新仿真时刻，产生波的动画效果
    %
    % ========================================================================
    % 修改日志 (CHANGELOG)
    % ========================================================================
    % 版本 v11 核心改进：
    %   - 使用 addlistener 和 ContinuousValueChange 事件，实现滑动条实时拖动
    %     （相比 v10 的 Callback，响应更灵敏）
    %   - 三视图共享同一仿真循环，用户可随时切换而不中断
    %   - 增强的错误处理和数值稳定性
    %
    % ========================================================================
    
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
    % 仿真系统的基础物理参数，用户通过UI滑动条可实时修改
    params.f     = 1e9;          % 信号频率 (Hz) - 默认 1 GHz
    params.Z0    = 50;           % 传输线特性阻抗 (Ω) - 标准值 50 Ω
    params.RL    = 50;           % 负载电阻部分 (Ω) - 实部
    params.XL    = -50;          % 负载电抗部分 (Ω) - 虚部（负值表示容性）
    params.Alpha = 0;            % 传输线衰减常数 (Np/m) - 0 表示无损线         
    
    % --- 创建主图形窗口 ---
    % 设置窗口的基本属性：大小、位置、外观、事件处理
    hFig = figure('Name', '电磁场课程设计：多维传输线综合分析平台 v11', ...
                  'NumberTitle', 'off', ...
                  'Color', theme.bg, ...
                  'Position', [50, 50, 1280, 760], ...  % [left, bottom, width, height]
                  'MenuBar', 'none', ...
                  'ToolBar', 'figure', ...
                  'InvertHardcopy', 'off', ...           % 打印时保持深色背景
                  'Renderer', 'opengl');                % 使用 OpenGL 渲染，支持 3D 和实时刷新 

    try
        %% --- UI 布局管理 (使用 Normalized 单位自适应) ---
        % 所有 UI 元素使用 Normalized 单位，确保在不同屏幕分辨率下都能正确适应
        % 坐标范围：[0,0] 在左下角，[1,1] 在右上角
        
        % 0. 顶部标题栏 - 程序的视觉焦点
        % 显示程序名称和版本，使用醒目的颜色和大号字体
        uicontrol('Parent', hFig, 'Style', 'text', 'String', 'ADVANCED EM LAB - 电磁场与波虚拟仿真平台', ...
                  'Units', 'normalized', 'Position', [0 0.94 1 0.06], ...
                  'FontSize', 16, 'FontWeight', 'bold', ...
                  'ForegroundColor', theme.cyan, 'BackgroundColor', theme.panel_bg);
    
        % 1. 顶部视图切换栏 - 用户可以在三种视图之间快速切换
        % 单选按钮组（ButtonGroup）确保同时只有一个选项被选中
        btn_group = uibuttongroup('Parent', hFig, ...
                                  'Units', 'normalized', 'Position', [0.01 0.87 0.25 0.06], ...
                                  'Title', '', 'BackgroundColor', theme.panel_bg, ...
                                  'SelectionChangedFcn', @on_view_change, ...  % 选择变化时的回调
                                  'BorderType', 'none');
        
        uicontrol(btn_group, 'Style', 'text', 'String', '视图模式 / VIEW MODE', ...
                  'Units', 'normalized', 'Position', [0.02 0.4 0.35 0.4], ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'FontSize', 9);
    
        % 三个单选按钮：2D、3D、Smith
        create_styled_radio(btn_group, [0.38 0.1 0.18 0.8], '2D', '2D', theme);
        create_styled_radio(btn_group, [0.58 0.1 0.18 0.8], '3D', '3D', theme);
        create_styled_radio(btn_group, [0.78 0.1 0.20 0.8], 'Smith', 'Smith', theme);
    
        % 2. 左侧参数控制面板 - 用户与仿真的主要交互界面
        % 面板包含四个滑动条（频率、特性阻抗、负载参数）和一个实时数据显示区域
        panel_ctrl = uipanel('Parent', hFig, 'Title', '', ...
                             'Units', 'normalized', 'Position', [0.01 0.02 0.25 0.84], ...
                             'BackgroundColor', theme.panel_bg, 'BorderType', 'none');
        
        uicontrol(panel_ctrl, 'Style', 'text', 'String', '参数控制 / PARAMETERS', ...
                  'Units', 'normalized', 'Position', [0.05 0.92 0.9 0.05], ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'FontSize', 11);
    
        % 创建四个参数滑动条，每个包括标签、滑动条和数值框
        % 用户可以通过滑动或直接输入来修改这些关键参数
        create_param_control(panel_ctrl, 0.82, '负载电阻 RL (Ω)', params.RL, 0, 200, @(v)update_val('RL',v), theme);
        create_param_control(panel_ctrl, 0.70, '负载电抗 XL (Ω)', params.XL, -200, 200, @(v)update_val('XL',v), theme);
        create_param_control(panel_ctrl, 0.58, '特性阻抗 Z0 (Ω)', params.Z0, 10, 200, @(v)update_val('Z0',v), theme);
        create_param_control(panel_ctrl, 0.46, '衰减常数 α (Np/m)', params.Alpha, 0, 0.99, @(v)update_val('Alpha',v), theme);
    
        % 实时指标显示区域 - 显示仿真计算出的关键参数
        uicontrol(panel_ctrl, 'Style', 'text', ...
                  'Units', 'normalized', 'Position', [0.05 0.35 0.9 0.04], ...
                  'String', '实时指标 / REAL-TIME DATA', 'FontWeight', 'bold', ...
                  'ForegroundColor', theme.green, 'BackgroundColor', theme.panel_bg, ...
                  'HorizontalAlignment', 'left');
              
        % 可编辑文本框：显示 VSWR、反射系数、回波损耗等关键指标
        % 设为 Enable='inactive' 使其只读（可选中和复制，但不能编辑）
        info_box = uicontrol(panel_ctrl, 'Style', 'edit', 'Max', 2, ...
                             'Units', 'normalized', 'Position', [0.05 0.02 0.9 0.32], ...
                             'String', 'System initializing...', 'FontSize', 10, 'FontName', 'Consolas', ...
                             'HorizontalAlignment', 'left', 'Enable', 'inactive', ...
                             'BackgroundColor', theme.bg, 'ForegroundColor', theme.cyan);
    
        % 3. 创建坐标轴
        % 四个坐标轴分别对应四种不同的可视化模式
        % 在运行时通过改变 Visible 属性来切换显示
        
        % 2D Upper Plot - 电压和电流分布
        % 显示：
        %   - 电压包络（驻波的最大幅度范围）
        %   - 电压瞬时值（随时间振荡）
        %   - 电流瞬时值（用于理解功率流）
        ax_2d_wave = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.56 0.66 0.32], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', '2D', 'Visible', 'on');
        grid(ax_2d_wave, 'on'); hold(ax_2d_wave, 'on');
        title(ax_2d_wave, 'Voltage & Current Distributions', 'Color', theme.text);
        
        % 2D Lower Plot - 阻抗分布
        % 显示：
        %   - |Z(z)| 沿传输线的变化
        %   - 参考线 Z0（完全匹配时的值）
        % 说明：驻波节处阻抗最小，驻波腹处阻抗最大
        ax_2d_imp = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.10 0.66 0.32], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', '2D', 'Visible', 'on');
        grid(ax_2d_imp, 'on'); hold(ax_2d_imp, 'on');
        title(ax_2d_imp, 'Impedance Magnitude |Z(z)|', 'Color', theme.text);
        
        % 3D Plot - 复平面上的波轨迹
        % 展示电压相量在复平面上的运动
        % X 轴：位置 (z/λ)
        % Y 轴：实部
        % Z 轴：虚部
        % 形成螺旋轨迹，反映了波的传播和反射特性
        ax_3d = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.30 0.10 0.66 0.80], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'ZColor', theme.text, ...
            'Tag', '3D', 'Visible', 'off');
        grid(ax_3d, 'on'); hold(ax_3d, 'on');
        view(ax_3d, [-40, 25]); axis(ax_3d, 'tight');
        title(ax_3d, '3D Phasor Space (Helix)', 'Color', theme.text);
        
        % Smith Chart - 标准化阻抗平面
        % 用反射系数 Γ = (Z - Z0)/(Z + Z0) 表示
        % 圆形网格表示常阻抗圆和常电纳圆
        % 用于阻抗匹配设计和 VSWR 分析
        ax_smith = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.35 0.10 0.56 0.78], ...
            'Color', theme.bg, 'XColor', theme.text, 'YColor', theme.text, 'Tag', 'Smith', 'Visible', 'off');
        axis(ax_smith, 'equal'); axis(ax_smith, 'off'); hold(ax_smith, 'on');
    
        %% --- 图形对象初始化 ---
        set(info_box, 'String', 'Generating Graphics Objects...'); drawnow;
        H = init_graphics_objects();
        
        % 初始化完成后，强制调用一次视图刷新，确保 Smith Chart 初始隐藏
        refresh_view_visibility('2D');
        
        set(info_box, 'String', 'System Ready.'); drawnow;

        % 启动仿真循环 ---
        % 设置基本的物理常数和时间参数
        c = 3e8;        % 光速 (m/s) - 电磁波在自由空间的传播速度
        t = 0;          % 当前仿真时刻 (s) - 从 0 开始
        dt = 1 / params.f / 150;  % 时间步长 = 1 个周期 / 150
                                   % 每个周期分 150 步，足以画出光滑的波形
        
        view_mode = '2D';  % 初始视图模式
        
        % 启动实时刷新定时器：每 50 ms 执行一次 animation_loop
        % 这样即使用户在拖动滑动条，仿真也持续运行
        t_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.05, 'TimerFcn', @animation_loop);
        start(t_timer);
        set(hFig, 'CloseRequestFcn', @close_gui);
        
    catch ME
        errordlg(sprintf('Initialization Failed:\n%s', ME.message), 'Error');
        delete(hFig);
    end

    %% --- 核心逻辑 ---

    % 关闭 GUI 的清理函数
    % 确保在关闭窗口时正确停止定时器和释放资源
    function close_gui(~, ~)
        try 
            stop(t_timer);      % 停止定时器
            delete(t_timer);    % 删除定时器对象，释放内存
        catch
            % 如果定时器已被删除，忽略错误
        end
        delete(hFig);  % 删除图形窗口
    end

    % 参数更新回调：当用户调整滑动条时，更新 params 结构体
    % name：参数名称（字符串）
    % val：新的参数值（数值）
    function update_val(name, val)
        params.(name) = val;
    end

    % 视图模式切换回调：当用户选择不同的单选按钮时触发
    % event.NewValue：新选中的单选按钮对象
    % event.NewValue.Tag：该按钮的标签字符串（'2D'、'3D' 或 'Smith'）
    function on_view_change(~, event)
        view_mode = event.NewValue.Tag;
        refresh_view_visibility(view_mode);
    end

    function refresh_view_visibility(mode)
        % 根据用户选择的视图模式，显示或隐藏相应的坐标轴和图形对象
        % 这确保三种不同的可视化方式不会相互干扰
        
        % 1. 先全部隐藏所有坐标轴
        set_visible(ax_2d_wave, 'off');
        set_visible(ax_2d_imp, 'off');
        set_visible(ax_3d, 'off');
        set_visible(ax_smith, 'off');
        
        % 2. 根据模式显示指定的坐标轴
        switch mode
            case '2D'
                % 2D 模式：显示两个子图（电压/电流 和 阻抗分布）
                set_visible(ax_2d_wave, 'on');
                set_visible(ax_2d_imp, 'on');
            case '3D'
                % 3D 模式：显示立体复平面坐标轴
                set_visible(ax_3d, 'on');
            case 'Smith'
                % Smith 图模式：显示标准化阻抗平面
                set_visible(ax_smith, 'on');
        end
        
        % 嵌套函数：同时隐藏坐标轴和其上的所有子对象
        function set_visible(ax, state)
            set(ax, 'Visible', state);
            ch = get(ax, 'Children');
            set(ch, 'Visible', state);
        end
    end

    function animation_loop(~, ~)
        try
            if ~isvalid(hFig), return; end
            
            %% --- 1. 物理计算：传输线基本参数和波传播特性 ---
            % 基于频率和特性阻抗，计算传输线的物理特征和反射特性
            
            % 1.1 计算波长和传播常数（关键物理参数）
            lambda = c / params.f;          % 波长 = 光速 / 频率，决定了空间周期
            w = 2 * pi * params.f;          % 角频率 (rad/s) = 2π × 频率
            beta = 2 * pi / lambda;         % 相位常数 (rad/m) - 描述波沿传输线的相位变化
            gamma_prop = params.Alpha + 1j * beta;  % 传播常数 = 衰减常数 + j×相位常数
                                                     % 完整描述波的衰减和传播特性
            
            % 1.2 计算负载阻抗和反射系数（关键参数：决定所有反射现象）
            Z_L = params.RL + 1j * params.XL;   % 负载阻抗 = 电阻 + j×电抗（复数形式）
            % 计算反射系数：衡量入射波在负载处的反射程度
            % Γ = (Z_L - Z0) / (Z_L + Z0)
            % 当 Z_L = Z0 时，Γ = 0（完全匹配，无反射）
            % 当 Z_L → ∞（开路）时，Γ → 1（全反射，同向）
            % 当 Z_L = 0（短路）时，Γ → -1（全反射，反向）
            Gamma_L = (Z_L - params.Z0) / (Z_L + params.Z0);
            if isnan(Gamma_L), Gamma_L = 0; end
            
            % 1.3 定义空间网格：沿传输线从负载向源端
            z_len = 2.0 * lambda;           % 仿真长度 = 2 倍波长（足以显示多个周期）
            z = linspace(-z_len, 0, 400);   % z：从 -2λ 到 0，共 400 个采样点
                                            % z = 0 处是负载，z → -∞ 是源端
            
            % 1.4 计算入射波和反射波的复包络（幅度和相位信息）
            V0_plus = 1;                    % 入射波幅度（1V，作为参考）
            % 入射波：沿 +z 方向衰减，幅度和相位都变化
            % exp(-gamma_prop * z) = exp(-α*z) × exp(-j*β*z)
            %                      = 衰减因子 × 相位延迟因子
            exp_pos = exp(gamma_prop * z);  % 反射波指数因子（∝ z）
            exp_neg = exp(-gamma_prop * z); % 入射波指数因子（∝ -z）
            time_phasor = exp(1j * w * t);  % 时间相位因子 exp(jωt)，用于生成时变波形
            
            % 入射波电压：随 z 衰减，随时间振荡
            V_inc_c = V0_plus * exp_neg .* time_phasor;
            % 反射波电压：从负载处反射，振幅乘以反射系数，向源端传播
            V_ref_c = V0_plus * Gamma_L * exp_pos .* time_phasor;
            % 总电压 = 入射波 + 反射波（叠加原理）
            % 这是传输线的核心方程：反射的存在导致驻波形成
            V_tot_c = V_inc_c + V_ref_c;
            
            % 1.5 计算电流分布（根据特性阻抗和电压推导）
            % 传输线电压和电流的关系：I = ±V/Z0（符号取决于波的方向）
            % 入射波：I+ = V+/Z0（同向）
            % 反射波：I- = -V-/Z0（反向，相位反转 180°）
            I_tot_c = (V0_plus / params.Z0) * (exp_neg - Gamma_L * exp_pos) .* time_phasor;
                      % 减号来自反射波方向相反
            
            % 1.6 计算阻抗分布（传输线理论的重要参数）
            % Z(z) = V(z) / I(z) - 沿传输线各点的本地阻抗
            % 在反射存在时，Z(z) 不是常数，形成驻波
            Z_dist = V_tot_c ./ I_tot_c;
            
            % 1.7 计算关键传输线指标
            % VSWR（电压驻波比）= (1 + |Γ|) / (1 - |Γ|)
            % VSWR = 1 时，完全匹配（最优）
            % VSWR > 1 时，有反射，VSWR 越大反射越强
            vswr = (1 + abs(Gamma_L))/(1 - abs(Gamma_L));
            if vswr > 100, vswr = 100; end  % 防止数值溢出
            % 回波损耗 (Return Loss) = -20*log10(|Γ|)，单位 dB
            % 指标越高，反射越小，匹配越好
            rl_dB = -20*log10(abs(Gamma_L)+eps);

            % --- 2. 图形更新：根据选择的视图模式显示仿真结果 ---
            switch view_mode
                case '2D'
                    % 2D 视图：电压、电流、阻抗沿传输线的分布
                    % 这展示了经典的驻波现象
                    
                    % 更新上图：电压幅度包络和瞬时值
                    set(H.v_env_up, 'XData', z/lambda, 'YData', abs(V_tot_c));  % 上包络：|V(z)|
                    set(H.v_env_dn, 'XData', z/lambda, 'YData', -abs(V_tot_c)); % 下包络：-|V(z)|
                    set(H.v_line,   'XData', z/lambda, 'YData', real(V_tot_c)); % 瞬时电压：Re[V(z,t)]
                    set(H.i_line,   'XData', z/lambda, 'YData', real(I_tot_c)*params.Z0); % 电流（乘以 Z0 便于同屏显示）
                    title(ax_2d_wave, sprintf('Voltage & Current (VSWR=%.2f)', vswr));
                    
                    % 更新下图：阻抗幅度分布
                    set(H.z_line,   'XData', z/lambda, 'YData', abs(Z_dist));  % |Z(z)| - 阻抗模
                    set(H.z0_line,  'XData', [min(z/lambda) 0], 'YData', [params.Z0 params.Z0]); % 参考线：Z0
                    % 说明：Z(z) 在驻波腹（压脉点）处最大，在驻波节处最小
                    
                case '3D'
                    % 3D 视图：在复平面上显示波的螺旋轨迹
                    % X 轴：沿传输线位置 (z/λ)
                    % Y 轴：电压的实部
                    % Z 轴：电压的虚部
                    % 这形成了椭圆螺旋，螺旋的旋转代表波的传播
                    
                    % 绘制合成波、入射波、反射波的复数轨迹
                    set(H.h3_tot, 'XData', z/lambda, 'YData', real(V_tot_c), 'ZData', imag(V_tot_c));
                    set(H.h3_inc, 'XData', z/lambda, 'YData', real(V_inc_c), 'ZData', imag(V_inc_c));
                    set(H.h3_ref, 'XData', z/lambda, 'YData', real(V_ref_c), 'ZData', imag(V_ref_c));
                    
                    % 在负载处（z=0）绘制电压相量
                    % 相量是复平面上的向量，其长度表示幅度，角度表示相位
                    v_inc_0 = V_inc_c(end);  % z=0 处入射波相量
                    set(H.q3_inc, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_inc_0), 'WData', imag(v_inc_0));
                    
                    v_ref_0 = V_ref_c(end);  % z=0 处反射波相量
                    set(H.q3_ref, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_ref_0), 'WData', imag(v_ref_0));
                                  
                    v_tot_0 = V_tot_c(end);  % z=0 处合成波相量 = 入射 + 反射
                    set(H.q3_tot, 'XData', 0, 'YData', 0, 'ZData', 0, ...
                                  'UData', 0, 'VData', real(v_tot_0), 'WData', imag(v_tot_0));

                case 'Smith'
                    % Smith 图：在标准化阻抗平面上显示反射系数和 VSWR 圆
                    % Smith 图是传输线工程中的核心工具，用于可视化阻抗和反射特性
                    
                    % VSWR 圆：所有相同 VSWR 的阻抗对应的反射系数点的轨迹
                    % 圆的半径 = |Γ|，圆心在实轴上
                    theta = linspace(0, 2*pi, 100);
                    rho = abs(Gamma_L); if rho > 1, rho = 1; end
                    set(H.s_vswr, 'XData', rho*cos(theta), 'YData', rho*sin(theta));
                    
                    % 反射系数点：在 Smith 圆内移动，随时间绕原点旋转
                    % 点的位置直接对应负载阻抗的反射特性
                    set(H.s_dot,  'XData', real(Gamma_L),  'YData', imag(Gamma_L));
                    set(H.s_txt1, 'String', sprintf('VSWR Circle = %.2f', vswr));
            end
            
            % 更新左侧面板的实时指标显示
            update_info_panel(Gamma_L, vswr, rl_dB);
            
            % 时间步进：每次更新时间增加 dt，用于生成时变的波形动画
            t = t + dt;
            drawnow limitrate;  % 限制刷新率，避免 CPU 过载 
            
        catch ME
            set(hFig, 'Name', ['Error: ' ME.message]);
        end
    end

    %% --- 图形初始化函数 ---
    function H = init_graphics_objects()
        % 初始化所有图形对象（曲线、向量、文字等）
        % 在主仿真循环中通过修改这些对象的属性来实现动画效果
        % 关键思想：一次性创建所有图形对象，动画只是更新数据
        
        %% --- 初始化 2D 视图的图形对象 ---
        % 2D 上图：电压和电流的分布
        % 包络线表示驻波的幅度变化，而振荡曲线表示瞬时值
        
        % 电压上包络：|V(z)| 的上边界，用虚线表示
        H.v_env_up = plot(ax_2d_wave, NaN, NaN, 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        % 电压下包络：-|V(z)| 的下边界
        H.v_env_dn = plot(ax_2d_wave, NaN, NaN, 'Color', [theme.green, 0.4], 'LineStyle', '--', 'LineWidth', 1.5);
        % 电压瞬时值：Re[V(z,t)]，实时振荡的曲线
        H.v_line   = plot(ax_2d_wave, NaN, NaN, 'Color', theme.cyan, 'LineWidth', 2.5);
        % 电流瞬时值：Re[I(z,t)]×Z0（乘以 Z0 是为了使幅度与电压相当，便于观察对比）
        H.i_line   = plot(ax_2d_wave, NaN, NaN, 'Color', theme.magenta, 'LineWidth', 1.5, 'LineStyle', '-.');
        legend(ax_2d_wave, {'Envelope', '', 'Voltage', 'Current'}, 'Location', 'northwest', 'TextColor', theme.text, 'Color', theme.panel_bg, 'EdgeColor', 'none');
        ylim(ax_2d_wave, [-2.5 2.5]);
        
        % 2D 下图：阻抗分布
        % |Z(z)| 沿传输线的变化，反映了匹配情况和驻波
        H.z_line   = plot(ax_2d_imp, NaN, NaN, 'Color', theme.yellow, 'LineWidth', 2);
        % 参考线：特性阻抗 Z0（虚线表示无反射时的值）
        H.z0_line  = line([0 0], [50 50], 'Parent', ax_2d_imp, 'Color', theme.green, 'LineStyle', '--');
        ylim(ax_2d_imp, [0, 200]);
        
        %% --- 初始化 3D 视图的图形对象 ---
        % 3D 视图在复平面上绘制电压的轨迹
        % 形成螺旋，螺旋的旋转代表波随时间的演化
        
        % 合成波 (总电压) 的 3D 轨迹：白色，最粗
        % 这是最关键的轨迹，显示反射效应的综合结果
        H.h3_tot = plot3(ax_3d, NaN, NaN, NaN, 'Color', [1 1 1], 'LineWidth', 3);
        % 入射波的 3D 轨迹：青色（参考）
        % 展示了无反射情况下的理想波形
        H.h3_inc = plot3(ax_3d, NaN, NaN, NaN, 'Color', theme.cyan, 'LineWidth', 1.5);
        % 反射波的 3D 轨迹：洋红色（参考）
        % 显示了由负载反射产生的波
        H.h3_ref = plot3(ax_3d, NaN, NaN, NaN, 'Color', theme.magenta, 'LineWidth', 1.5);
        
        % 在负载处（z=0）绘制相量（向量）
        % 相量用箭头表示，其指向代表波的幅度和相位
        % 合成波相量：白色，最粗，表示负载处的总电压
        H.q3_tot = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', [1 1 1], 'LineWidth', 4, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
        % 入射波相量：青色
        H.q3_inc = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', theme.cyan, 'LineWidth', 2, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
        % 反射波相量：洋红色
        H.q3_ref = quiver3(ax_3d, 0,0,0, 0,1,0, 'Color', theme.magenta, 'LineWidth', 2, 'MaxHeadSize', 0.5, 'AutoScale', 'off');

        zlim(ax_3d, [-2 2]); ylim(ax_3d, [-2 2]);
        xlabel(ax_3d, 'z (\lambda)'); ylabel(ax_3d, 'Real'); zlabel(ax_3d, 'Imag');
        
        %% --- 初始化 Smith 图 ---
        % Smith 图是传输线设计的标准工具
        % 横轴：反射系数的实部
        % 纵轴：反射系数的虚部
        % 圆形网格：常阻抗圆和常电纳圆
        
        smith_data = prepare_smith_chart();
        % 绘制常阻抗圆（虚线）：连接相同实部阻抗的点
        for i = 1:length(smith_data.r_circles)
            c = smith_data.r_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        % 绘制常电纳圆：连接相同虚部阻抗的点
        for i = 1:length(smith_data.x_circles)
            c = smith_data.x_circles{i};
            plot(ax_smith, c.x, c.y, 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
        end
        % 实轴参考线
        plot(ax_smith, [-1 1], [0 0], 'Color', [0.5 0.5 0.5]);
        
        % VSWR 圆：所有相同 VSWR 的阻抗对应的反射系数点的轨迹
        % 用绿色虚线表示，通过修改其半径来动态显示不同的 VSWR
        H.s_vswr = plot(ax_smith, NaN, NaN, 'Color', theme.green, 'LineWidth', 2, 'LineStyle', '--');
        % 反射系数点：在 Smith 圆内移动
        % 点的位置直接对应当前的负载阻抗和反射特性
        H.s_dot  = plot(ax_smith, NaN, NaN, 'o', 'MarkerSize', 10, 'MarkerFaceColor', theme.magenta, 'MarkerEdgeColor', 'w');
        
        text(0, 1.2, 'Smith Chart', 'Parent', ax_smith, 'Color', theme.text, 'FontSize', 14, 'HorizontalAlignment', 'center');
        % VSWR 圆标注文本
        H.s_txt1 = text(0, -1.2, '', 'Parent', ax_smith, 'Color', theme.green, 'HorizontalAlignment', 'center', 'FontSize', 12);
    end

    function update_info_panel(Gamma, vswr, rl)
        % 更新左侧控制面板的实时数据显示
        % 这些参数是传输线理论的核心指标，直观显示系统的匹配和反射特性
        
        str = {
            '---------------------------';
            ' STATUS MONITOR';
            '---------------------------';
            ' [KEY METRICS] 关键指标';
            % VSWR（电压驻波比）：衡量阻抗匹配程度的关键指标
            % VSWR = 1：完美匹配，无反射（理想情况）
            % VSWR > 1：存在反射，VSWR 越大匹配越差
            % VSWR → ∞：开路或短路（完全不匹配）
            sprintf(' VSWR       : %.3f', vswr);
            % 反射系数的模：0 到 1 之间的数值
            % |Γ| = 0：无反射（完全匹配）
            % |Γ| = 1：完全反射（开路/短路）
            % |Γ| = 0.5：50% 的功率被反射
            sprintf(' Gamma Mag  : %.3f', abs(Gamma));
            % 反射系数的相位：决定反射波与入射波的时间关系
            % 0°：反射波与入射波同向
            % 180°：反射波与入射波反向（如短路）
            % 其他角度：部分匹配的情况
            sprintf(' Gamma Ang  : %.1f deg', rad2deg(angle(Gamma)));
            % 回波损耗：反射功率与入射功率的比值（dB 单位）
            % RL = 0 dB：全反射
            % RL = -6 dB：一半功率反射
            % RL < -20 dB：良好匹配（通常的工程要求）
            sprintf(' Return Loss: %.1f dB', rl);
            ' ';
            ' [PARAMETERS] 负载和线路参数';
            % 特性阻抗：决定入射波幅度和传输线的物理特性
            sprintf(' Z0 (Char)  : %.1f Ohm', params.Z0);
            % 负载电阻：决定能量吸收和损耗
            sprintf(' RL (Load)  : %.1f Ohm', params.RL);
            % 负载电抗：与频率相关的能量储存特性
            % 正值（感性）：线圈
            % 负值（容性）：电容
            sprintf(' XL (Load)  : %+.1f j', params.XL);
            % 衰减常数：模拟真实传输线的损耗
            % 单位 Np/m（Neper/meter）
            % 0：无损线
            % > 0：有损线，会随距离衰减
            sprintf(' Alpha      : %.3f Np/m', params.Alpha);
        };
        set(info_box, 'String', str);
    end

    %% --- 辅助工具函数 ---
    
    % 创建样式化的单选按钮
    % parent：父容器（通常是 ButtonGroup）
    % pos：位置 [left, bottom, width, height]
    % str：按钮标签文本
    % tag：用于识别选中哪个按钮的标签字符串
    % th：主题颜色结构体
    function create_styled_radio(parent, pos, str, tag, th)
        uicontrol(parent, 'Style', 'radiobutton', 'String', str, ...
            'Units', 'normalized', 'Position', pos, ...
            'Tag', tag, 'BackgroundColor', th.panel_bg, ...
            'ForegroundColor', th.text, 'FontSize', 10);
    end

    function create_param_control(parent, y_pos, label, val_init, min_v, max_v, callback, th)
        % 创建一个参数控制组件，包括标签、滑动条和数值输入框
        % 用户可以通过拖动滑动条或直接输入数值来修改参数
        
        % 标签：显示参数的名称和单位
        uicontrol(parent, 'Style', 'text', ...
            'Units', 'normalized', 'Position', [0.05 y_pos 0.9 0.04], ...
            'String', label, 'HorizontalAlignment', 'left', ...
            'BackgroundColor', th.panel_bg, 'ForegroundColor', th.text_dim, 'FontSize', 10);
        
        % 修改点1：创建滑动条
        % 滑动条允许用户在 [min_v, max_v] 范围内光滑地调节参数
        % 这是相比离散按钮的主要优势
        sld = uicontrol(parent, 'Style', 'slider', ...
            'Units', 'normalized', 'Position', [0.05 y_pos-0.05 0.65 0.04], ...
            'Min', min_v, 'Max', max_v, 'Value', val_init, 'BackgroundColor', th.bg);
        
        % 数值输入框
        % 用户也可以在这里直接输入具体数值，而不一定要用滑动条
        ed = uicontrol(parent, 'Style', 'edit', ...
            'Units', 'normalized', 'Position', [0.75 y_pos-0.05 0.20 0.04], ...
            'String', num2str(val_init), 'BackgroundColor', [0.2 0.2 0.22], ...
            'ForegroundColor', th.cyan, 'FontSize', 10);
        
        % 修改点2：【核心修复】添加监听器，实现实时拖动响应
        % 传统的 Callback 只能在鼠标松开时触发（非常不流畅）
        % addlistener 监听 'ContinuousValueChange' 事件，在拖动过程中实时触发
        % 这样用户拖动滑动条时，图形会立即刷新，体验更好
        addlistener(sld, 'ContinuousValueChange', @(s,~) sync_ui(s, ed, callback));
        
        % 保留原 Callback 以支持点击跳转（点击滑动条的某个位置直接跳过去）
        set(sld, 'Callback', @(s,~) sync_ui(s, ed, callback));
        % 数值框的回车键回调
        set(ed, 'Callback', @(e,~) sync_ui(e, sld, callback));
        
        % 内部函数：同步滑动条和输入框，调用参数更新回调
        function sync_ui(src, target, cb)
            % 根据数据源的类型提取数值
            val = get(src, 'Value');
            if strcmp(get(src, 'Style'), 'edit')
                % 从输入框读取并尝试转换为数值
                val = str2double(get(src, 'String'));
                % 限制输入值在允许范围内
                if val < min_v, val = min_v; elseif val > max_v, val = max_v; end
                if isnan(val), val = min_v; end  % 非法输入时使用最小值
            end
            % 同步两个 UI 组件的值
            set(sld, 'Value', val);
            set(ed, 'String', num2str(val));
            % 调用回调函数更新物理参数
            cb(val);
        end
    end

    function data = prepare_smith_chart()
        % 生成标准 Smith 图的网格数据
        % Smith 图是传输线工程中的关键工具，用于可视化复阻抗和反射系数的关系
        
        data.r_circles = {};  % 常阻抗圆：实部（电阻）相同的点
        data.x_circles = {};  % 常电纳圆：虚部（电抗）相同的点
        
        % 常阻抗圆的创建
        % Smith 图将复阻抗空间映射到单位圆内的反射系数空间
        % 常阻抗圆在 Smith 图中显示为垂直于实轴的圆
        r_vals = [0, 0.5, 1, 2, 5];  % 标准化阻抗的实部值（除以 Z0）
        t = linspace(0, 2*pi, 100);  % 参数化角度
        for k = 1:length(r_vals)
            r = r_vals(k);
            % Smith 图的变换公式：Γ = (Z - 1) / (Z + 1)，其中 Z = r + jx
            % 常阻抗圆的圆心和半径可通过化简得出
            cx = r / (1+r);       % 圆心 x 坐标
            cy = 0;               % 圆心 y 坐标（在实轴上）
            rad = 1 / (1+r);      % 圆的半径
            data.r_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
        end
        
        % 常电纳圆的创建
        % 常电纳圆在 Smith 图中显示为垂直于虚轴的圆
        % 这些圆表示虚部（电抗）相同的阻抗值
        x_vals = [0.5, 1, 2];  % 标准化阻抗的虚部值（除以 Z0）
        for k = 1:length(x_vals)
            x = x_vals(k);
            % 常电纳圆（感性，x > 0）
            cx = 1;       % 圆心 x 坐标
            cy = 1/x;     % 圆心 y 坐标
            rad = 1/x;    % 圆的半径
            data.x_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
            
            % 常电纳圆（容性，x < 0）
            cy = -1/x;    % 圆心 y 坐标（负值）
            data.x_circles{end+1} = struct('x', cx + rad*cos(t), 'y', cy + rad*sin(t));
        end
    end
end