function [blk] = synth_init(blk,varargin)

    log_group = 'synth_init_debug';
    % clog('entering synth_init', {log_group, 'trace'});

    % Set default vararg values.
    % reg_retiming is not an actual parameter of this block, but it is included
    % in defaults so that same_state will return false for blocks drawn prior to
    % adding reg_retiming='on' to some of the underlying Delay blocks.
    defaults = { ...
        'n_parout', 0, ...
        'sum_latency', 1, ...
        'n_ph_bits', 8, ...
        'n_amp_bits', 8, ...
        'out_type', 'Sine and Cosine' ...
        };

    check_mask_type(blk, 'synth');

    if same_state(blk, 'defaults', defaults, varargin{:}), return, end
    munge_block(blk, varargin{:});

    n_parout                = get_var('n_parout', 'defaults', defaults, varargin{:});
    sum_latency                = get_var('sum_latency', 'defaults', defaults, varargin{:});
    n_ph_bits               = get_var('n_ph_bits', 'defaults', defaults, varargin{:});
    n_amp_bits                 = get_var('n_amp_bits', 'defaults', defaults, varargin{:});
    out_type                 = get_var('out_type', 'defaults', defaults, varargin{:});

    delete_lines(blk);

    %default state, do nothing
    if (n_parout == 0),
        clean_blocks(blk);
        save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
        % clog('exiting synth_init', {log_group, 'trace'});
        return;
    end

    %%%%%%%%%%%%%%%%%%%%%%
    % parameter checking %
    %%%%%%%%%%%%%%%%%%%%%%

    if n_ph_bits < 1
        error('Too few bits for PHASE resolution');
    end

    if n_amp_bits < 1
        error('Too few bits for AMPLITUDE resolution');
    end

    if n_parout < 2
        error('Minimum demux factor of 2');
    end

    if sum_latency < 1
        error('Adder latency should be at least 1');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%S
    % input ports with gotos %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    xpos = 50; xinc = 80;
    ypos = 50; yinc = 80;

    port_w = 30; port_d = 14;
    const_w = 30; const_d = 20;
    mux_w = 50; mux_d = 150;
    bus_create_w = 50; bus_create_d = 500;
    sincos_w = 50; sincos_d = 50;
    del_w = 20; del_d = 20;
    adder_w = 50; adder_d = 50;
    gt_w = 50; gt_d = 20;

    %%%%%%%%%%%%%%%
    % input ports %
    %%%%%%%%%%%%%%%
    xpos_tmp = xpos;
    ypos_tmp = ypos;
    reuse_block(blk,'rst','built-in/inport',...
        'Port','1','Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'demux_times_dphi','built-in/inport',...
        'Port','2','Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'dphi','built-in/inport',...
        'Port','3','Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'phi0','built-in/inport',...
        'Port','4','Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % goto for reset distribution %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    xpos_tmp = xpos_tmp + xinc;
    ypos_tmp = ypos;
    reuse_block(blk,'rst_gt','simulink/Signal Routing/Goto',...
        'GotoTag', 'gt_rst', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    add_line(blk,'rst/1','rst_gt/1');

    %%%%%%%%%%%%%%%%%%%%%
    % mux input signals %
    %%%%%%%%%%%%%%%%%%%%%
    xpos_tmp = xpos_tmp + xinc;
    ypos_tmp = ypos + 2.5*yinc;
    reuse_block(blk,'rst_Ddphi_fr','simulink/Signal Routing/From',...
        'GotoTag', 'gt_rst', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    ypos_tmp = ypos_tmp + yinc;
    reuse_block(blk,'zero_Ddphi','xbsIndex_r4/Constant',...
        'const',num2str(0),...
        'explicit_period','on','arith_type','Unsigned',...
        'n_bits',num2str(n_ph_bits),'bin_pt',num2str(0),...
        'Position',[xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2]);
    ypos_tmp = ypos_tmp + 2*yinc;

    reuse_block(blk,'rst_dphi_fr','simulink/Signal Routing/From',...
        'GotoTag', 'gt_rst', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    ypos_tmp = ypos_tmp + yinc;
    reuse_block(blk,'zero_dphi','xbsIndex_r4/Constant',...
        'const',num2str(0),...
        'explicit_period','on','arith_type','Unsigned',...
        'n_bits',num2str(n_ph_bits),'bin_pt',num2str(0),...
        'Position',[xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2]);
    ypos_tmp = ypos_tmp + 2*yinc;

    reuse_block(blk,'rst_phi0_fr','simulink/Signal Routing/From',...
        'GotoTag', 'gt_rst', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    ypos_tmp = ypos_tmp + yinc;
    reuse_block(blk,'zero_phi0','xbsIndex_r4/Constant',...
        'const',num2str(0),...
        'explicit_period','on','arith_type','Unsigned',...
        'n_bits',num2str(n_ph_bits),'bin_pt',num2str(0),...
        'Position',[xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2]);

    %%%%%%%%%
    % muxes %
    %%%%%%%%%
    xpos_tmp = xpos_tmp + xinc;
    ypos_tmp = ypos + 3*yinc;
    reuse_block(blk,'mux_Ddphi','xbsIndex_r4/Mux',...
        'Inputs','2','Position',[xpos_tmp-mux_w/2 ypos_tmp-mux_d/2 xpos_tmp+mux_w/2 ypos_tmp+mux_d/2]);
    ypos_tmp = ypos_tmp + 3*yinc;
    add_line(blk,'rst_Ddphi_fr/1','mux_Ddphi/1');
    add_line(blk,'zero_Ddphi/1','mux_Ddphi/3');
    add_line(blk,'demux_times_dphi/1','mux_Ddphi/2');
    reuse_block(blk,'mux_dphi','xbsIndex_r4/Mux',...
        'Inputs','2','Position',[xpos_tmp-mux_w/2 ypos_tmp-mux_d/2 xpos_tmp+mux_w/2 ypos_tmp+mux_d/2]);
    add_line(blk,'rst_dphi_fr/1','mux_dphi/1');
    add_line(blk,'zero_dphi/1','mux_dphi/3');
    add_line(blk,'dphi/1','mux_dphi/2');
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'mux_phi0','xbsIndex_r4/Mux',...
        'Inputs','2','Position',[xpos_tmp-mux_w/2 ypos_tmp-mux_d/2 xpos_tmp+mux_w/2 ypos_tmp+mux_d/2]);
    add_line(blk,'rst_phi0_fr/1','mux_phi0/1');
    add_line(blk,'zero_phi0/1','mux_phi0/3');
    add_line(blk,'phi0/1','mux_phi0/2');


    %%%%%%%%%%%%%%%
    % mux outputs %
    %%%%%%%%%%%%%%%
    xpos_tmp = xpos_tmp + xinc;
    ypos_tmp = ypos + 3*yinc;
    reuse_block(blk,'Ddphi_gt','simulink/Signal Routing/Goto',...
        'GotoTag', 'gt_Ddphi', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    add_line(blk,'mux_Ddphi/1','Ddphi_gt/1');
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'dphi_gt','simulink/Signal Routing/Goto',...
        'GotoTag', 'gt_dphi', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    add_line(blk,'mux_dphi/1','dphi_gt/1');
    ypos_tmp = ypos_tmp + 3*yinc;
    reuse_block(blk,'phi0_gt','simulink/Signal Routing/Goto',...
        'GotoTag', 'gt_phi0', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    add_line(blk,'mux_phi0/1','phi0_gt/1');

    %%%%%%%%%%%%%%%%
    % master adder %
    %%%%%%%%%%%%%%%%
    ypos_tmp = ypos;
    xpos_tmp = xpos_tmp + xinc;
    reuse_block(blk,'Ddphi_fr','simulink/Signal Routing/From',...
        'GotoTag', 'gt_Ddphi', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    xpos_tmp = xpos_tmp + xinc;
    reuse_block(blk,'masterSum','xbsMath_r4/AddSub',...
        'precision', 'User Defined', 'mode', 'Addition',...
        'arith_type', 'Unsigned', 'n_bits', num2str(n_ph_bits), ...
        'bin_pt', num2str(0), 'Latency', num2str(sum_latency), ...
        'Position',[xpos_tmp-adder_w/2 ypos_tmp-adder_d/2 xpos_tmp+adder_w/2 ypos_tmp+adder_d/2]);
    add_line(blk, 'Ddphi_fr/1','masterSum/2');
    add_line(blk, 'masterSum/1','masterSum/1');

    %%%%%%%%%%%%%%%%
    % offset adder %
    %%%%%%%%%%%%%%%%
    xpos_tmp = xpos_tmp + xinc;
    ypos_tmp = ypos_tmp + yinc;
    reuse_block(blk,'phi0_fr','simulink/Signal Routing/From',...
        'GotoTag', 'gt_phi0', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    xpos_tmp = xpos_tmp + xinc;
    reuse_block(blk,'offsetSum','xbsMath_r4/AddSub',...
        'precision', 'User Defined', 'mode', 'Addition',...
        'arith_type', 'Unsigned', 'n_bits', num2str(n_ph_bits), ...
        'bin_pt', num2str(0), 'Latency', num2str(sum_latency), ...
        'Position',[xpos_tmp-adder_w/2 ypos_tmp-adder_d/2 xpos_tmp+adder_w/2 ypos_tmp+adder_d/2]);
    add_line(blk, 'masterSum/1','offsetSum/1');
    add_line(blk, 'phi0_fr/1','offsetSum/2');

    %%%%%%%%%%%%%%%%%%
    % parallel steps %
    %%%%%%%%%%%%%%%%%%
    for ii=1:n_parout
        % increment phase
        if ii ~= 1
            xpos_tmp = xpos_tmp + xinc;
            ypos_tmp = ypos_tmp + yinc;
            reuse_block(blk,sprintf('dphi%d_fr',ii-1),'simulink/Signal Routing/From',...
                'GotoTag', 'gt_dphi', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
            xpos_tmp = xpos_tmp + xinc;
            reuse_block(blk,sprintf('step%dSum',ii-1),'xbsMath_r4/AddSub',...
                'precision', 'User Defined', 'mode', 'Addition',...
                'arith_type', 'Unsigned', 'n_bits', num2str(n_ph_bits), ...
                'bin_pt', num2str(0), 'Latency', num2str(sum_latency), ...
                'Position',[xpos_tmp-adder_w/2 ypos_tmp-adder_d/2 xpos_tmp+adder_w/2 ypos_tmp+adder_d/2]);
            if ii==2
                add_line(blk, 'offsetSum/1',sprintf('step%dSum/1',ii-1));
            else
                add_line(blk, sprintf('step%dSum/1',ii-2),sprintf('step%dSum/1',ii-1));
            end
            add_line(blk, sprintf('dphi%d_fr/1',ii-1),sprintf('step%dSum/2',ii-1));
        end
        % add delay compensation for following stages
        if ii < n_parout
            xpos_tmp = xpos_tmp + xinc;
            reuse_block(blk,sprintf('del%d',ii-1),'xbsIndex_r4/Delay',...
                'Latency',num2str((n_parout-ii)*sum_latency),...
                'Position',[xpos_tmp-del_w/2 ypos_tmp-del_d/2 xpos_tmp+del_w/2 ypos_tmp+del_d/2]);
            if ii == 1
                add_line(blk, 'offsetSum/1', sprintf('del%d/1',ii-1));
            else
                add_line(blk, sprintf('step%dSum/1',ii-1), sprintf('del%d/1',ii-1));
            end
        end
        % phase generator
        xpos_tmp = xpos_tmp + xinc;
        reuse_block(blk,sprintf('sc%d',ii-1),'casper_library_downconverter/sincos',...
            'bit_width',num2str(n_amp_bits),'depth_bits',num2str(n_ph_bits),...
            'func',lower(out_type),...
            'Position',[xpos_tmp-sincos_w/2 ypos_tmp-sincos_d/2 xpos_tmp+sincos_w/2 ypos_tmp+sincos_d/2]);
        if ii < n_parout
            add_line(blk, sprintf('del%d/1',ii-1), sprintf('sc%d/1',ii-1));
        else
            add_line(blk, sprintf('step%dSum/1',ii-1), sprintf('sc%d/1',ii-1));
        end
    end

    %%%%%%%%%%%%%%
    % output bus %
    %%%%%%%%%%%%%%
    xpos_tmp = xpos_tmp + 5*xinc;
    ypos_tmp = ypos;
    sc_oport = 0;
    if strfind(out_type,'Sine')
        sc_oport = sc_oport + 1;
        reuse_block(blk,'sbus','casper_library_flow_control/bus_create',...
            'inputNum',num2str(n_parout),...
            'Position',[xpos_tmp-bus_create_w/2 ypos_tmp-bus_create_d/2 xpos_tmp+bus_create_w/2 ypos_tmp+bus_create_d/2]);
        for ii=1:n_parout
            add_line(blk, sprintf('sc%d/%d',ii-1,sc_oport), sprintf('sbus/%d',ii));
        end
        xpos_tmp = xpos_tmp + 2*xinc;
        reuse_block(blk,'sin','built-in/outport',...
            'Port',sprintf('%d',sc_oport),...
            'Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);
        add_line(blk,'sbus/1','sin/1');
        ypos_tmp = ypos + bus_create_d + yinc;
        xpos_tmp = xpos_tmp - 2*xinc;
    end
    if strfind(out_type,'Cosine')
        sc_oport = sc_oport + 1;
        reuse_block(blk,'cbus','casper_library_flow_control/bus_create',...
            'inputNum',num2str(n_parout),...
            'Position',[xpos_tmp-bus_create_w/2 ypos_tmp-bus_create_d/2 xpos_tmp+bus_create_w/2 ypos_tmp+bus_create_d/2]);
        for ii=1:n_parout
            add_line(blk, sprintf('sc%d/%d',ii-1,sc_oport), sprintf('cbus/%d',ii));
        end
        xpos_tmp = xpos_tmp + 2*xinc;
        reuse_block(blk,'cos','built-in/outport',...
            'Port',sprintf('%d',sc_oport),...
            'Position',[xpos_tmp-port_w/2,ypos_tmp-port_d/2,xpos_tmp+port_w/2,ypos_tmp+port_d/2]);
        add_line(blk,'cbus/1','cos/1');
    end

    % When finished drawing blocks and lines, remove all unused blocks.
    clean_blocks(blk);

    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

    % clog('exiting synth_init', {log_group, 'trace'});

end %function synth_init
