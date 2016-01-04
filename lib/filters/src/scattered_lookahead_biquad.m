function [Bsla,Asla] = scattered_lookahead_biquad(B,A,M,is_real,tol)
% Add scattered look-ahead pipelining to a biquad filter
%
% [Bsla,Asla] = scattered_lookahead_biquad(B,A,M) adds scattered look-ahead
% to the biquad filter B,A such that the feedback path requires only delays
% of integer multiples of M samples. The filter with look-ahead is returned
% in Bsla,Asla.
%
% [Bsla,Asla] = scattered_lookahead_biquad(B,A,M,is_real) will return only
% real-valued coefficients in Bsla and Asla if is_real evaluates to true.
%
% [Bsla,Asla] = scattered_lookahead_biquad(B,A,M,is_real,tol) will set
% coefficients in Bsla and Asla equal to zero when their magnitudes are
% smaller than tol. If tol is not given, default value is 1e-16.

    if nargin < 4
        is_real = false;
    end
    
    if nargin < 5
        tol = 1e-16;
    end
    
    % Feedback path should have real coefficients, complex-conj pair poles
    poles = roots(A);
    r = abs(poles(1)); % equal magnitude, use (1)
    p0 = mean(angle(poles)); % symmetric about real-axis, take mean (0?)
    dp = abs(angle(poles(1))-p0);
    
    % Rotations
    Asla = A;
    Bsla = B;
    for ii=1:M-1
        pr = 2*pi*ii/M + angle(poles);
        new_pz = r*exp(1i*pr);
        new_poly = conv([1,-new_pz(1)],[1,-new_pz(2)]);
%         pr = 2*pi*ii/M + p0 - dp;
%         new_pz = r*exp(1i*2*pi*pr);
%         new_poly = conv(new_poly,conv([1,-new_pz(1)],[1,-conj(new_pz(1))]));
        Asla = conv(Asla,new_poly); 
        Bsla = conv(Bsla,new_poly); % poles and zeros in same location
    end
    
    if is_real
        Bsla = real(Bsla);
        Asla = real(Asla);
    end
    
    Asla(abs(Asla) < tol) = 0;
    Bsla(abs(Bsla) < tol) = 0;
end