function [blk] = synth_input_init(blk,varargin)

  log_group = 'synth_input_init_debug';
  % clog('entering synth_input_init', {log_group, 'trace'});
  
  % Set default vararg values.
  % reg_retiming is not an actual parameter of this block, but it is included
  % in defaults so that same_state will return false for blocks drawn prior to
  % adding reg_retiming='on' to some of the underlying Delay blocks.
  defaults = { ...
    'io_delay', 0, ...
    'sim_in', 'off',...
    'dphi',0,...
    'demux_dphi',0,...
    'phi0',0 ...
  };  
  
  check_mask_type(blk, 'synth_input');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  io_delay                   = get_var('io_delay', 'defaults', defaults, varargin{:});
  sim_in                     = get_var('sim_in', 'defaults', defaults, varargin{:});
  dphi                       = get_var('dphi','defaults',defaults,varargin{:});
  demux_dphi                 = get_var('demux_dphi','defaults',defaults,varargin{:});
  phi0                       = get_var('phi0','defaults',defaults,varargin{:});

  %%%%%%%%%%%%%%%%%%%%%%
  % parameter checking %
  %%%%%%%%%%%%%%%%%%%%%%
  
  if io_delay < 0
      warning('I/O delay should be non-negative, setting to zero');
      io_delay = 0;
  end
  
  % delete lines
  delete_lines(blk);
  
  xpos = 330; xinc = 200;
  ypos = 315; yinc = 80;

  swreg_w = 100; swreg_d = 28;
  feed_w = 100; feed_d = 100;
  
  % connect 'always-there' blocks
  add_line(blk,'dphi/1','slc0/1');
  add_line(blk,'dphi/1','slc1/1');
  add_line(blk,'dphi/1','slc2/1');
  
  add_line(blk,'slc0/1','bigdphi/1');
  add_line(blk,'slc1/1','smalldphi/1');
  add_line(blk,'slc2/1','phi0/1');
  
  % reuse the register block
  xpos_tmp = xpos;
  ypos_tmp = ypos;
  reuse_block(blk,'dphi','xps_library/software register',...
      'Position',[xpos_tmp-swreg_w/2 ypos_tmp-swreg_d/2 xpos_tmp+swreg_w/2 ypos_tmp+swreg_d/2],...
      'io_delay',num2str(io_delay),...
      'sim_port',sim_in,...
      'io_dir','From Processor',...
      'mode','one value');
 
  % if sim-input
  xpos_tmp = xpos - xinc;
  ypos_tmp = ypos + feed_d/2;
  if strcmpi(sim_in,'on')
      reuse_block(blk,'feed','synths/synth_feed_3x10bit_plus2bit',...
          'Position',[xpos_tmp-feed_w/2 ypos_tmp-feed_d/2 xpos_tmp+feed_w/2 ypos_tmp+feed_d/2],...
          'dphi',num2str(dphi),...
          'demux_dphi',num2str(demux_dphi),...
          'phi0',num2str(phi0));
      add_line(blk,'feed/1','dphi/1');
  end

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  % clog('exiting synth_input_init', {log_group, 'trace'});

end %function synth_input_init

