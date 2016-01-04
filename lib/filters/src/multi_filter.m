function [y,Y] = multi_filter(B,A,x)
% Pass input through multiple filter stages
%
% y = multi_filter(B,A,x) passes the input x through filters defined by the
% rows in each B,A and returns the result in y.
%
% [y,Y] = multi_filter(B,A,x) also returns in each column Y the output of
% each filter stage (row in B,A).

    N_x = numel(x);
    N_stages = size(B,1);
    
    if nargout > 1
        Y = zeros(N_x,N_stages);
    end
    
    y = x;
    for ii=1:N_stages
        y = filter(B(ii,:),A(ii,:),y);
        if nargout > 1
            Y(:,ii) = y;
        end
    end
    
end