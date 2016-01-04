function [blk] = coeff_16x8bit_bus_init(blk,varargin)

  log_group = 'coeff_16x8bit_bus_init_debug';
  % clog('entering coeff_16x8bit_bus_init', {log_group, 'trace'});
  
  % Set default vararg values.
  % reg_retiming is not an actual parameter of this block, but it is included
  % in defaults so that same_state will return false for blocks drawn prior to
  % adding reg_retiming='on' to some of the underlying Delay blocks.
  defaults = { ...
    'io_delay', 0, ...
    'sim_in', 'off',...
    'coeff',[1,2,3,4]...
  };  
  
  check_mask_type(blk, 'coeff_16x8bit_bus');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  io_delay                   = get_var('io_delay', 'defaults', defaults, varargin{:});
  sim_in                     = get_var('sim_in', 'defaults', defaults, varargin{:});
  coeff                      = get_var('coeff','defaults',defaults,varargin{:});

  %%%%%%%%%%%%%%%%%%%%%%
  % parameter checking %
  %%%%%%%%%%%%%%%%%%%%%%
  
  if io_delay < 0
      warning('I/O delay should be non-negative, setting to zero');
      io_delay = 0;
  end
  
  if numel(coeff) ~= 4% || ~strcmpi('uint32',class(coeff))
      error('Coefficients vector should contain exactly four uint32 values');
  end
  
  % delete lines
  delete_lines(blk);
  
  xpos = 260; xinc = 200;
  ypos = 172; yinc = 80;

  swreg_w = 100; swreg_d = 28;
  feed_w = 100; feed_d = 200;
  
  % connect 'always-there' blocks
  add_line(blk,'bb0/4','bus_create/16');
  add_line(blk,'bb0/3','bus_create/15');
  add_line(blk,'bb0/2','bus_create/14');
  add_line(blk,'bb0/1','bus_create/13');
  add_line(blk,'bb1/4','bus_create/12');
  add_line(blk,'bb1/3','bus_create/11');
  add_line(blk,'bb1/2','bus_create/10');
  add_line(blk,'bb1/1','bus_create/9');
  add_line(blk,'bb2/4','bus_create/8');
  add_line(blk,'bb2/3','bus_create/7');
  add_line(blk,'bb2/2','bus_create/6');
  add_line(blk,'bb2/1','bus_create/5');
  add_line(blk,'bb3/4','bus_create/4');
  add_line(blk,'bb3/3','bus_create/3');
  add_line(blk,'bb3/2','bus_create/2');
  add_line(blk,'bb3/1','bus_create/1');
  
  add_line(blk,'bus_create/1','coeffbus/1');
  
  % reuse the register blocks with correct settings
  xpos_tmp = xpos;
  ypos_tmp = ypos;
  for ii=3:-1:0
      reuse_block(blk,sprintf('g%d',ii),'xps_library/software register',...
          'Position',[xpos_tmp-swreg_w/2 ypos_tmp-swreg_d/2 xpos_tmp+swreg_w/2 ypos_tmp+swreg_d/2],...
          'io_delay',num2str(io_delay),...
          'sim_port',sim_in,...
          'io_dir','From Processor',...
          'mode','one value');
      add_line(blk,sprintf('g%d/1',ii),sprintf('bb%d/1',ii));
      ypos_tmp = ypos_tmp + yinc;
  end
  
  % if sim-input
  xpos_tmp = xpos - xinc;
  ypos_tmp = ypos + feed_d/2;
  if strcmpi(sim_in,'on')
      reuse_block(blk,'feed','filters/coeff_4x32bit_feed',...
          'Position',[xpos_tmp-feed_w/2 ypos_tmp-feed_d/2 xpos_tmp+feed_w/2 ypos_tmp+feed_d/2],...
          'coeff',mat2str(coeff));
      for ii=1:4
          add_line(blk,sprintf('feed/%d',ii),sprintf('g%d/1',4-ii));
      end
  end

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  % clog('exiting coeff_16x8bit_bus_init', {log_group, 'trace'});

end %function coeff_16x8bit_bus_init

