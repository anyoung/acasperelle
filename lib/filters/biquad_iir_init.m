function [blk] = biquad_iir_init(blk,varargin)

  log_group = 'biquad_iir_init_debug';
  % clog('entering biquad_iir_init', {log_group, 'trace'});
  
  % Set default vararg values.
  % reg_retiming is not an actual parameter of this block, but it is included
  % in defaults so that same_state will return false for blocks drawn prior to
  % adding reg_retiming='on' to some of the underlying Delay blocks.
  defaults = { ...
    'n_bits_in', 0,  'bin_pt_in',     7, ...
    'n_bits_coeff', 0,  'bin_pt_coeff',     7, ...
    'n_bits_out', 16,  'bin_pt_out',     14, ...
    'b_vec', [1.0 0.0 0.0], ...
    'a_vec', [1.0 0.0 0.0] ...
  };  
  
  check_mask_type(blk, 'biquad_iir');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  n_bits_in                  = get_var('n_bits_in', 'defaults', defaults, varargin{:});
  bin_pt_in                  = get_var('bin_pt_in', 'defaults', defaults, varargin{:});
  n_bits_coeff               = get_var('n_bits_coeff', 'defaults', defaults, varargin{:});
  bin_pt_coeff               = get_var('bin_pt_coeff', 'defaults', defaults, varargin{:});
  n_bits_out                 = get_var('n_bits_out', 'defaults', defaults, varargin{:});
  bin_pt_out                 = get_var('bin_pt_out', 'defaults', defaults, varargin{:});
  b_vec                      = get_var('b_vec', 'defaults', defaults, varargin{:});
  a_vec                      = get_var('a_vec', 'defaults', defaults, varargin{:});
  
  delete_lines(blk);

  %default state, do nothing 
  if (n_bits_in == 0 | n_bits_coeff == 0),
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    % clog('exiting biquad_iir_init', {log_group, 'trace'});
    return;
  end

  %%%%%%%%%%%%%%%%%%%%%%
  % parameter checking %
  %%%%%%%%%%%%%%%%%%%%%%
  
  if any(n_bits_in < bin_pt_in)
      error('Too few bits for given binary point for INPUT');
  end

  if any(n_bits_coeff< bin_pt_coeff)
      error('Too few bits for given binary point for COEFF');
  end
  
  if any(n_bits_out < bin_pt_out)
      error('Too few bits for given binary point for OUT');
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % input ports            %
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos = 50; xinc = 100;
  ypos = 50; yinc = 100;

  port_w = 30; port_d = 14;
  const_w = 20; const_d = 20;
  dec_fir_w = 80; dec_fir_d = 120;
  c_to_ri_w = 50; c_to_ri_d = 50;
  ri_to_c_w = 50; ri_to_c_d = 50;
  feedback_iir_w = 80; feedback_iir_d = 50;
  term_w = 20; term_d = 20;

  ypos_tmp = ypos;
  reuse_block(blk, 'sync_in', 'built-in/inport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk, 'din_c', 'built-in/inport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  
  %%%%%%%%%%%%%%%%%%%
  % convert c-to-ri %
  %%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos + xinc;
  ypos_tmp = ypos + yinc;
  reuse_block(blk, 'c2ri_in', 'casper_library_misc/c_to_ri', ...
    'Position', [xpos_tmp-c_to_ri_w/2 ypos_tmp-c_to_ri_d/2 xpos_tmp+c_to_ri_w/2 ypos_tmp+c_to_ri_d/2],...
    'n_bits',num2str(n_bits_in),'bin_pt',num2str(bin_pt_in));
  add_line(blk,'din_c/1','c2ri_in/1');
  
  %%%%%%%%%%%%%%%
  % add dec_fir %
  %%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos;
  try
      reuse_block(blk, 'dec_fir', 'casper_library_downconverter/dec_fir', ...
        'Position', [xpos_tmp-dec_fir_w/2 ypos_tmp-dec_fir_d/2 xpos_tmp+dec_fir_w/2 ypos_tmp+dec_fir_d/2],...
        'n_inputs','1','n_bits',num2str(n_bits_out),'n_bits_bp',num2str(bin_pt_out),...
        'add_latency','1','mult_latency','3',...
        'coeff',mat2str(b_vec(:)'),...
        'coeff_bit_width',num2str(n_bits_coeff),'coeff_bin_pt',num2str(bin_pt_coeff));
  catch ME
      if strcmpi(ME.identifier,'Simulink:Commands:ParamUnknown')
          warning('dec_fir does not define n_bits_bp? Check below error message');
          fprintf(1,'\n\n%s\n\n',ME.getReport());
          reuse_block(blk, 'dec_fir', 'casper_library_downconverter/dec_fir', ...
            'Position', [xpos_tmp-dec_fir_w/2 ypos_tmp-dec_fir_d/2 xpos_tmp+dec_fir_w/2 ypos_tmp+dec_fir_d/2],...
            'n_inputs','1','n_bits',num2str(n_bits_out),...
            'add_latency','1','mult_latency','3',...
            'coeff',mat2str(b_vec(:)'),...
            'coeff_bit_width',num2str(n_bits_coeff),'coeff_bin_pt',num2str(bin_pt_coeff));
      else
          rethrow(ME);
      end
  end
  add_line(blk,'sync_in/1','dec_fir/1');
  add_line(blk,'c2ri_in/1','dec_fir/2');
  add_line(blk,'c2ri_in/2','dec_fir/3');
  
  %%%
  % add convert c-to-ri %
  %%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos + yinc;
  reuse_block(blk, 'c2ri_fir', 'casper_library_misc/c_to_ri', ...
    'Position', [xpos_tmp-c_to_ri_w/2 ypos_tmp-c_to_ri_d/2 xpos_tmp+c_to_ri_w/2 ypos_tmp+c_to_ri_d/2],...
    'n_bits',num2str(n_bits_out),'bin_pt',num2str(bin_pt_out));
  add_line(blk,'dec_fir/2','c2ri_fir/1');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % add feedback-path for re- and im-components %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + 2*xinc;
  ypos_tmp = ypos + yinc/2;
  reuse_block(blk,'feedback_re','filters/feedback_iir',...
      'Position', [xpos_tmp-feedback_iir_w/2 ypos_tmp-feedback_iir_d/2 xpos_tmp+feedback_iir_w/2 ypos_tmp+feedback_iir_d/2],...
      'n_bits',num2str(n_bits_out),'bin_pt',num2str(bin_pt_out),'n_bits_coeff',num2str(n_bits_coeff),'bin_pt_coeff',num2str(bin_pt_coeff),...
      'a_vec',mat2str(a_vec(:)'));
  add_line(blk,'dec_fir/1','feedback_re/1');
  add_line(blk,'c2ri_fir/1','feedback_re/2');
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk,'feedback_im','filters/feedback_iir',...
      'Position', [xpos_tmp-feedback_iir_w/2 ypos_tmp-feedback_iir_d/2 xpos_tmp+feedback_iir_w/2 ypos_tmp+feedback_iir_d/2],...
      'n_bits',num2str(n_bits_out),'bin_pt',num2str(bin_pt_out),'n_bits_coeff',num2str(n_bits_coeff),'bin_pt_coeff',num2str(bin_pt_coeff),...
      'a_vec',mat2str(a_vec(:)'));
  add_line(blk,'c2ri_fir/2','feedback_im/2');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % add dummy sync for feedback_im %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp - xinc;
  ypos_tmp = ypos_tmp - yinc/2;
  reuse_block(blk,'dummy_sync', 'xbsIndex_r4/Constant', ...
    'Position', [xpos_tmp-const_w/2 ypos_tmp-const_d/2 xpos_tmp+const_w/2 ypos_tmp+const_d/2],...
    'const','0','arith_type','Boolean',...
    'explicit_period','on');
  add_line(blk,'dummy_sync/1','feedback_im/1');
  xpos_tmp = xpos_tmp + 2*xinc;
  reuse_block(blk,'dummy_term','built-in/terminator',...
    'Position', [xpos_tmp-term_w/2 ypos_tmp-term_d/2 xpos_tmp+term_w/2 ypos_tmp+term_d/2]);
  add_line(blk,'feedback_im/1','dummy_term/1');  

  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % combine output ri-to-c %
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + 2*xinc;
  ypos_tmp = ypos + yinc;
  reuse_block(blk, 'ri2c_iir', 'casper_library_misc/ri_to_c', ...
    'Position', [xpos_tmp-ri_to_c_w/2 ypos_tmp-ri_to_c_d/2 xpos_tmp+ri_to_c_w/2 ypos_tmp+ri_to_c_d/2]);
  add_line(blk,'feedback_re/2','ri2c_iir/1');
  add_line(blk,'feedback_im/2','ri2c_iir/2');
  
  %%%%%%%%%%%%%%
  % add output %
  %%%%%%%%%%%%%%
  xpos_tmp = xpos_tmp + xinc;
  ypos_tmp = ypos;
  reuse_block(blk, 'sync_out', 'built-in/outport', ...
    'Port', '1', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc;
  reuse_block(blk, 'dout_c', 'built-in/outport', ...
    'Port', '2', 'Position', [xpos_tmp-port_w/2 ypos_tmp-port_d/2 xpos_tmp+port_w/2 ypos_tmp+port_d/2]);
  add_line(blk,'feedback_re/1','sync_out/1');
  add_line(blk,'ri2c_iir/1','dout_c/1');
  
  warning(['Checking ', blk, '/dec_fir/convert(1|2) for consistency']);
  conv1_bin_pt = get_param([blk, '/dec_fir/convert1'],'bin_pt');
  conv2_bin_pt = get_param([blk, '/dec_fir/convert2'],'bin_pt');
  if ~strcmpi(conv1_bin_pt,conv2_bin_pt) | ~strcmpi(conv1_bin_pt,num2str(bin_pt_out))
      warning('Inconsistent binary-point in real and imaginary components of dec_fir. correcting.');
      set_param([blk, '/dec_fir/convert1'],'bin_pt',num2str(bin_pt_out));
      set_param([blk, '/dec_fir/convert2'],'bin_pt',num2str(bin_pt_out));
  end
  
  % When finished drawing blocks and lines, remove all unused blocks.
%   clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  % clog('exiting biquad_iir_init', {log_group, 'trace'});

end %function biquad_iir_init

