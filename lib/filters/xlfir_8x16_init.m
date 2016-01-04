function [blk] = xlfir_8x16_init(blk,varargin)

  log_group = 'xlfir_8x16_init_debug';
  % clog('entering xlfir_8x16_init', {log_group, 'trace'});
  
  % Set default vararg values.
  % reg_retiming is not an actual parameter of this block, but it is included
  % in defaults so that same_state will return false for blocks drawn prior to
  % adding reg_retiming='on' to some of the underlying Delay blocks.
  defaults = { ...
    'n_bits_data', 0,  'bin_pt_data',     7, ...
    'n_bits_coeff', 0,  'bin_pt_coeff',     7, ...
    'n_bits_out', 16,  'bin_pt_out',     14 ...
  };  
  
  check_mask_type(blk, 'xlfir_8x16');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  n_bits_data                = get_var('n_bits_data', 'defaults', defaults, varargin{:});
  bin_pt_data                = get_var('bin_pt_data', 'defaults', defaults, varargin{:});
  n_bits_coeff               = get_var('n_bits_coeff', 'defaults', defaults, varargin{:});
  bin_pt_coeff               = get_var('bin_pt_coeff', 'defaults', defaults, varargin{:});
  n_bits_out                 = get_var('n_bits_out', 'defaults', defaults, varargin{:});
  bin_pt_out                 = get_var('bin_pt_out', 'defaults', defaults, varargin{:});
  
  delete_lines(blk);

  %default state, do nothing 
  if (n_bits_data == 0 | n_bits_coeff == 0),
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    % clog('exiting xlfir_8x16_init', {log_group, 'trace'});
    return;
  end

  %%%%%%%%%%%%%%%%%%%%%%
  % parameter checking %
  %%%%%%%%%%%%%%%%%%%%%%
  
  if any(n_bits_data < bin_pt_data)
      error('Too few bits for given binary point for DATA');
  end

  if any(n_bits_coeff< bin_pt_coeff)
      error('Too few bits for given binary point for COEFF');
  end
  
  if any(n_bits_out < bin_pt_out)
      error('Too few bits for given binary point for OUT');
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % check input lists for consistency %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  lenba = length(n_bits_data); lenpa = length(bin_pt_data);
  a = [lenba, lenpa];  
  unique_a = unique(a);
  compa = unique_a(length(unique_a));

  lenbb = length(n_bits_coeff); lenpb = length(bin_pt_coeff);
  b = [lenbb, lenpb];  
  unique_b = unique(b);
  compb = unique_b(length(unique_b));

  lenbo = length(n_bits_out); lenpo = length(bin_pt_out);
  o = [lenbo, lenpo];
  unique_o = unique(o);
  compo = unique_o(length(unique_o));

  too_many_a = length(unique_a) > 2;
  conflict_a = (length(unique_a) == 2) && (unique_a(1) ~= 1);
  if too_many_a || conflict_a,
    error('conflicting component number for bus a');
    % clog('conflicting component number for bus a', {'error', log_group});
  end

  too_many_b = length(unique_b) > 2;
  conflict_b = (length(unique_b) == 2) && (unique_b(1) ~= 1);
  if too_many_b || conflict_b,
    error('conflicting component number for bus b');
    % clog('conflicting component number for bus b', {'error', log_group});
  end

  too_many_o = length(unique_o) > 2;
  conflict_o = (length(unique_o) == 2) && (unique_o(1) ~= 1);
  if too_many_o || conflict_o,
    error('conflicting component number for output bus');
    % clog('conflicting component number for output bus', {'error', log_group});
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % autocomplete input lists where necessary %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  comp = max(compa, compb);

  %replicate items if needed for a input
  n_bits_data      = repmat(n_bits_data, 1, compa/lenba); 
  bin_pt_data      = repmat(bin_pt_data, 1, compa/lenpa); 

  %replicate items if needed for b input
  n_bits_coeff      = repmat(n_bits_coeff, 1, compb/lenbb); 
  bin_pt_coeff      = repmat(bin_pt_coeff, 1, compb/lenpb);
  
  %replicate items if needed for output
  compo         = comp;
  n_bits_out    = repmat(n_bits_out, 1, comp/lenbo);
  bin_pt_out    = repmat(bin_pt_out, 1, comp/lenpo);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%S
  % input ports with gotos %
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos = 50; xinc = 80;
  ypos = 50; yinc = 400;

  port_w = 30; port_d = 14;
  bus_expand_w = 50; bus_expand_d = 200;
  adder_tree_w = 50; adder_tree_d = 200;
  bus_mult_w = 50; bus_mult_d = 120;
  bus_del_w = 30; bus_del_d = 20;
  del_w = 20; del_d = 20;
  term_w = 20; term_d = 20;
  gt_w = 50; gt_d = 20;

  ypos_tmp = ypos;
  reuse_block(blk, 'sync_in', 'built-in/inport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  xpos_tmp = xpos + xinc;
  reuse_block(blk, 'sync_mul_delay','xbsIndex/Delay',...
      'Latency','3',...
      'Position',[xpos_tmp-del_w/2 ypos_tmp-del_d/2 xpos_tmp+del_w/2 ypos_tmp+del_d/2]);
  add_line(blk,'sync_in/1','sync_mul_delay/1');
  xpos_tmp = xpos_tmp + xinc;
  reuse_block(blk,'sync_in_gt', 'simulink/Signal Routing/Goto', ...
      'GotoTag', 'gt_sync_in', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
  add_line(blk,'sync_mul_delay/1','sync_in_gt/1');

  ypos_tmp = ypos_tmp + yinc/2;
  reuse_block(blk, 'data', 'built-in/inport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  xpos_tmp = xpos + xinc;
  reuse_block(blk,'data_gt', 'simulink/Signal Routing/Goto', ...
      'GotoTag', 'gt_data', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
  add_line(blk,'data/1','data_gt/1');
  ypos_tmp = ypos_tmp + yinc;
  
  for ii=1:8
    reuse_block(blk, sprintf('cb%d',ii-1), 'built-in/inport', ...
        'Port', sprintf('%d',ii+2), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    xpos_tmp = xpos + xinc;
    reuse_block(blk,sprintf('cb%d_gt',ii-1), 'simulink/Signal Routing/Goto', ...
        'GotoTag', sprintf('gt_cb%d',ii-1), 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
    add_line(blk,sprintf('cb%d/1',ii-1),sprintf('cb%d_gt/1',ii-1));
    ypos_tmp = ypos_tmp + yinc;
  end
  
  %%%%%%%%%
  % froms %
  %%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc;
  for ii=1:8
      reuse_block(blk,sprintf('sync_in%d_fr',ii-1), 'simulink/Signal Routing/From', ...
          'GotoTag', 'gt_sync_in', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
      ypos_tmp = ypos_tmp + bus_mult_d/2;
      reuse_block(blk,sprintf('data%d_fr',ii-1), 'simulink/Signal Routing/From', ...
          'GotoTag', 'gt_data', 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
      ypos_tmp = ypos_tmp + bus_mult_d/2;
      reuse_block(blk,sprintf('cb%d_fr',ii-1), 'simulink/Signal Routing/From', ...
          'GotoTag', sprintf('gt_cb%d',ii-1), 'Position', [xpos_tmp-gt_w/2 ypos_tmp-gt_d/2 xpos_tmp+gt_w/2 ypos_tmp+gt_d/2]);
      ypos_tmp = ypos_tmp - bus_mult_d + yinc;
  end
  
  %%%%%%%%%%
  % delays %
  %%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc;
  for ii=1:8
      if ii ~= 1
          reuse_block(blk,sprintf('bus_del%d',ii-1), 'casper_library_bus/bus_delay', ...
              'n_bits',mat2str(n_bits_data*ones(1,16)),'latency',num2str(ii-1), ...
              'cmplx', 'off', 'misc', 'off', ...
              'Position', [xpos_tmp-bus_del_w/2, ypos_tmp-bus_del_d/2, xpos_tmp+bus_del_w/2, ypos_tmp+bus_del_w/2]);
      end
      ypos_tmp = ypos_tmp + yinc;
  end
  
  
  %%%%%%%%%%%%%%%
  % multipliers %
  %%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc + bus_mult_d/2;
  for ii=1:8
      reuse_block(blk,sprintf('bus_mul%d',ii-1), 'casper_library_bus/bus_mult', ...
          'n_bits_a',mat2str(ones(1,16)*n_bits_data),'bin_pt_a',mat2str(ones(1,16)*bin_pt_data), 'type_a', mat2str(ones(1,16)*1), ...
          'n_bits_b',mat2str(ones(1,16)*n_bits_coeff),'bin_pt_b',mat2str(ones(1,16)*bin_pt_coeff), 'type_b', mat2str(ones(1,16)*1), ...
          'n_bits_out',mat2str(ones(1,16)*(n_bits_out-7)),'bin_pt_out',mat2str(ones(1,16)*bin_pt_out), 'type_out', mat2str(ones(1,16)*1), ...
          'cmplx_a', 'off', 'cmplx_b', 'off','misc', 'off', ...
          'Position', [xpos_tmp-bus_mult_w/2, ypos_tmp-bus_mult_d/2, xpos_tmp+bus_mult_w/2, ypos_tmp+bus_mult_w/2]);
      if ii ~= 1
          add_line(blk,sprintf('data%d_fr/1',ii-1),sprintf('bus_del%d/1',ii-1));
          add_line(blk,sprintf('bus_del%d/1',ii-1),sprintf('bus_mul%d/1',ii-1));
      else
          add_line(blk,sprintf('data%d_fr/1',ii-1),sprintf('bus_mul%d/1',ii-1));
      end
      add_line(blk,sprintf('cb%d_fr/1',ii-1),sprintf('bus_mul%d/2',ii-1));
      ypos_tmp = ypos_tmp + yinc;
  end
  
  
  %%%%%%%%%%%%%%
  % bus expand %
  %%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc + bus_expand_d/2;
  for ii=1:8
      reuse_block(blk,sprintf('bus_exp%d',ii-1), 'casper_library_flow_control/bus_expand', ...
          'outputNum','16','outputWidth',num2str(n_bits_out-7),'outputBinaryPt',num2str(bin_pt_out),'outputArithmeticType',num2str(1),...
          'Position', [xpos_tmp-bus_expand_w/2, ypos_tmp-bus_expand_d/2, xpos_tmp+bus_expand_w/2, ypos_tmp+bus_expand_d/2]);
      ypos_tmp = ypos_tmp + yinc;
      add_line(blk,sprintf('bus_mul%d/1',ii-1),sprintf('bus_exp%d/1',ii-1));
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%
  % intra-mul adder tree %
  %%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + 5*xinc;
  ypos_tmp = ypos + yinc + adder_tree_w/2;
  for ii=1:8
      reuse_block(blk,sprintf('adder_tree%d',ii-1), 'casper_library_misc/adder_tree', ...
          'n_inputs','16',...
          'Position', [xpos_tmp-adder_tree_w/2, ypos_tmp-adder_tree_d/2, xpos_tmp+adder_tree_w/2, ypos_tmp+adder_tree_d/2]);
      ypos_tmp = ypos_tmp + yinc;
      for jj=1:16
          add_line(blk,sprintf('bus_exp%d/%d',ii-1,jj),sprintf('adder_tree%d/%d',ii-1,jj+1));
      end
      add_line(blk,sprintf('sync_in%d_fr/1',ii-1),sprintf('adder_tree%d/1',ii-1));
  end
  
  %%%%%%%%%%%%%%%
  % terminators %
  %%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc;
  for ii=1:8
      if ii ~= 1
          reuse_block(blk,sprintf('term%d',ii-1),'simulink/Sinks/Terminator',...
              'Position', [xpos_tmp-term_w/2, ypos_tmp-term_d/2, xpos_tmp+term_w/2, ypos_tmp+term_d/2]);
      end
      ypos_tmp = ypos_tmp + yinc;
  end
  
  %%%%%%%%%%%%%%%%%%%%%
  % global adder tree %
  %%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + 5*xinc;
  ypos_tmp = ypos + yinc*5 + adder_tree_d/2;
  reuse_block(blk,'adder_tree_global', 'casper_library_misc/adder_tree', ...
          'n_inputs','8',...
          'Position', [xpos_tmp-adder_tree_w/2, ypos_tmp-adder_tree_d*10, xpos_tmp+adder_tree_w/2, ypos_tmp+adder_tree_d*10]);
  for ii=1:8
      if ii ~= 1
          add_line(blk,sprintf('adder_tree%d/1',ii-1),sprintf('term%d/1',ii-1));
      else
          add_line(blk,sprintf('adder_tree%d/1',ii-1),'adder_tree_global/1');
      end
      add_line(blk,sprintf('adder_tree%d/2',ii-1),sprintf('adder_tree_global/%d',ii+1));
  end
  
  %%%%%%%%%%%%%%%%%
  % output port/s %
  %%%%%%%%%%%%%%%%%
  ypos_tmp = ypos + yinc*5 + adder_tree_d*10/4;
  xpos_tmp = xpos_tmp + xinc;
  reuse_block(blk, 'sync_out', 'built-in/outport', ...
    'Port', '1', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk, ['adder_tree_global/1'], ['sync_out/1']);
  ypos_tmp = ypos_tmp + adder_tree_d*10/2;  
  reuse_block(blk, 'y', 'built-in/outport', ...
    'Port', '2', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk, ['adder_tree_global/2'], ['y/1']);

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  % clog('exiting xlfir_8x16_init', {log_group, 'trace'});

end %function xlfir_8x16_init

