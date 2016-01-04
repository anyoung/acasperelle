function [] = print_filter(B,A)
% B and A should be the same length.
    N = numel(B)-1;
    fprintf(1,'\n\n%dth-order filter:\n\n',N);
    s_num = sprintf('%+5.3f*z^(-%d) ',[B; 0:N]);
    fprintf(1,'\t       %s\n',s_num);
    fprintf(1,'\tH(z) = %s\n',repmat('-',[1,numel(s_num)-1]));
    s_den = sprintf('%+5.3f*z^(-%d) ',[A; 0:N]);
    fprintf(1,'\t       %s\n',s_den);
end