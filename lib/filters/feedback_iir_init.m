function [blk] = feedback_iir_init(blk,varargin)

  log_group = 'feedback_iir_init_debug';
  % clog('entering feedback_iir_init', {log_group, 'trace'});
  
  % Set default vararg values.
  % reg_retiming is not an actual parameter of this block, but it is included
  % in defaults so that same_state will return false for blocks drawn prior to
  % adding reg_retiming='on' to some of the underlying Delay blocks.
  defaults = { ...
    'n_bits', 0,  'bin_pt',     7, ...
    'n_bits_coeff', 0,  'bin_pt_coeff',     7, ...
    'a_vec', [1.0 0.0 0.0] ...
  };  
  
  check_mask_type(blk, 'feedback_iir');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  n_bits                     = get_var('n_bits', 'defaults', defaults, varargin{:});
  bin_pt                     = get_var('bin_pt', 'defaults', defaults, varargin{:});
  n_bits_coeff               = get_var('n_bits_coeff', 'defaults', defaults, varargin{:});
  bin_pt_coeff               = get_var('bin_pt_coeff', 'defaults', defaults, varargin{:});
  a_vec                      = get_var('a_vec', 'defaults', defaults, varargin{:});
  
  delete_lines(blk);

  %default state, do nothing 
  if (n_bits == 0 | n_bits_coeff == 0),
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    % clog('exiting feedback_iir_init', {log_group, 'trace'});
    return;
  end

  %%%%%%%%%%%%%%%%%%%%%%
  % parameter checking %
  %%%%%%%%%%%%%%%%%%%%%%
  
  if any(n_bits < bin_pt)
      error('Too few bits for given binary point for INPUT/OUTPUT');
  end

  if any(n_bits_coeff< bin_pt_coeff)
      error('Too few bits for given binary point for COEFF');
  end
  
  if nnz(a_vec) ~= 3
      error('A-coefficient vector must have exactly three non-zero elements, one on each end and one in the middle.');
  end
  
  if a_vec(1) ~= 1
      error('First A-coefficient must equal 1.0');
  end
  
  idx_nnz = find(a_vec ~= 0);
  diff_idx_nnz = diff(idx_nnz);
  if diff_idx_nnz(1) ~= diff_idx_nnz(2)
      error('Non-zero coefficients should be symmetrically distributed around middle');
  end
  delay_step = diff_idx_nnz(1);
  
  %%%%%%%%%%%%%%%
  % input ports %
  %%%%%%%%%%%%%%%
  xpos = 50; xinc = 100;
  ypos = 50; yinc = 100;

  port_w = 30; port_d = 14;
  del_w = 20; del_d = 20;
  addsub_w = 50; addsub_d = 50;
  mul_w = 50; mul_d = 50;
  const_w = 80; const_d = 30;
  gt_w = 50; gt_d = 20;

  ypos_tmp = ypos;
  reuse_block(blk, 'sync_in', 'built-in/inport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk, 'din', 'built-in/inport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % add feedback-subtract and sync delay %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos + 2*xinc;
  ypos_tmp = ypos;
  reuse_block(blk,'sync_delay','xbsIndex_r4/Delay',...
    'Position', [xpos_tmp-del_w/2 ypos_tmp-del_d/2 xpos_tmp+del_w/2 ypos_tmp+del_d/2],...
    'latency',num2str(2*delay_step));
  add_line(blk,'sync_in/1','sync_delay/1');
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk, 'feedback_sub', 'xbsIndex_r4/AddSub', ...
    'Position', [xpos_tmp-addsub_w/2 ypos_tmp-addsub_d/2 xpos_tmp+addsub_w/2 ypos_tmp+addsub_d/2],...
    'mode','Subtraction','precision','User Defined','overflow','Saturate',...
    'quantization','Round  (unbiased: +/- Inf)','n_bits',num2str(n_bits),...
    'bin_pt',num2str(bin_pt),'arith_type','Signed  (2''s comp)',...
    'latency','0');
  add_line(blk,'din/1','feedback_sub/1');
  
  %%%%%%%%%%%%%%
  % add output %
  %%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos;
  reuse_block(blk, 'sync_out', 'built-in/outport', ...
    'Port', '1', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk,'sync_delay/1','sync_out/1');
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk, 'dout', 'built-in/outport', ...
    'Port', '2', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk,'feedback_sub/1','dout/1');
  
  %%%%%%%%%%%%%%%%%%%%
  % add coefficients %
  %%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + 2*yinc;
  reuse_block(blk, sprintf('a%d',delay_step), 'xbsIndex_r4/Constant', ...
    'Position', [xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2],...
    'Orientation','left',...
    'const',num2str(a_vec(idx_nnz(2))),'arith_type','Signed (2''s comp)',...
    'n_bits',num2str(n_bits_coeff),'bin_pt',num2str(bin_pt_coeff),'explicit_period','on');
  ypos_tmp = ypos_tmp + 2*yinc;
  reuse_block(blk, sprintf('a%d',delay_step*2), 'xbsIndex_r4/Constant', ...
    'Position', [xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2],...
    'Orientation','left',...
    'const',num2str(a_vec(idx_nnz(3))),'arith_type','Signed (2''s comp)',...
    'n_bits',num2str(n_bits_coeff),'bin_pt',num2str(bin_pt_coeff),'explicit_period','on');
  
  %%%%%%%%%%%%%%%%%%%
  % add multipliers %
  %%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp - xinc;
  ypos_tmp = ypos + 2*yinc;
  reuse_block(blk, sprintf('mul_a%d',delay_step), 'xbsIndex_r4/Mult', ...
    'Position', [xpos_tmp-mul_w/2 ypos_tmp-mul_d/2 xpos_tmp+mul_w/2 ypos_tmp+mul_d/2],...
    'Orientation','left',...
    'precision','User Defined','overflow','Saturate',...
    'quantization','Round  (unbiased: +/- Inf)','n_bits',num2str(n_bits),...
    'bin_pt',num2str(bin_pt),'arith_type','Signed  (2''s comp)',...
    'latency',num2str(delay_step-1));
  add_line(blk,sprintf('a%d/1',delay_step),sprintf('mul_a%d/1',delay_step));
  add_line(blk,'feedback_sub/1',sprintf('mul_a%d/2',delay_step));
  ypos_tmp = ypos_tmp + 2*yinc;
  reuse_block(blk, sprintf('mul_a%d',delay_step*2), 'xbsIndex_r4/Mult', ...
    'Position', [xpos_tmp-mul_w/2 ypos_tmp-mul_d/2 xpos_tmp+mul_w/2 ypos_tmp+mul_d/2],...
    'Orientation','left',...
    'precision','User Defined','overflow','Saturate',...
    'quantization','Round  (unbiased: +/- Inf)','n_bits',num2str(n_bits),...
    'bin_pt',num2str(bin_pt),'arith_type','Signed  (2''s comp)',...
    'latency',num2str(delay_step-1));
  add_line(blk,sprintf('a%d/1',2*delay_step),sprintf('mul_a%d/1',2*delay_step));
  add_line(blk,'feedback_sub/1',sprintf('mul_a%d/2',2*delay_step));
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % add delay for a_vec(end) %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp - xinc;
  reuse_block(blk,'feedback_delay','xbsIndex_r4/Delay',...
    'Position', [xpos_tmp-del_w/2 ypos_tmp-del_d/2 xpos_tmp+del_w/2 ypos_tmp+del_d/2],...
    'Orientation','left',...
    'latency',num2str(delay_step));
  add_line(blk,sprintf('mul_a%d/1',2*delay_step),'feedback_delay/1');
  
  %%%%%%%%%%%%%%%%%%%%%%%%
  % add sum for feedback %
  %%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp - xinc;
  ypos_tmp = ypos_tmp - yinc;
  reuse_block(blk, 'feedback_add', 'xbsIndex_r4/AddSub', ...
    'Position', [xpos_tmp-addsub_w/2 ypos_tmp-addsub_d/2 xpos_tmp+addsub_w/2 ypos_tmp+addsub_d/2],...
    'Orientation','left',...
    'mode','Addition','precision','User Defined','overflow','Saturate',...
    'quantization','Round  (unbiased: +/- Inf)','n_bits',num2str(n_bits),...
    'bin_pt',num2str(bin_pt),'arith_type','Signed  (2''s comp)',...
    'latency','1');
  add_line(blk,sprintf('mul_a%d/1',delay_step),'feedback_add/1');
  add_line(blk,'feedback_delay/1','feedback_add/2');
  add_line(blk,'feedback_add/1','feedback_sub/2');

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  % clog('exiting feedback_iir_init', {log_group, 'trace'});

end %function feedback_iir_init

