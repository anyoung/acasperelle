function [bq_B,bq_A] = filter_to_biquads(B,A,tf)
% Subdivide higher-order filter into a number of biquad structures
%
% [bq_B,bq_A] = filter_to_biquads(B,A) subdivides the 2N-order filter
% specified by B,A into N biquad filters. bq_B and bq_A are Nx3 arrays in
% which each row bq_B(ii,:),bq_A(ii,:) defines a biquad structure.
%
% [bq_B,bq_A] = filter_to_biquads(B,A,TF) also prints diagnostic
% information to standard out and plots characteristics if TF evaluates to
% true.
%
% Subdivision is determined by starting with poles nearest unit-circle,
% pairing them with closest zeros, and moving on to poles all the farther
% from the unit-circle.
%
    if nargin < 3
        tf = false;
    end

    % subdivide filter into biquad structures
    z_poles = roots(A);
    z_zeros = roots(B);
    N_zp = numel(z_poles);
    zp_pairs = zeros(N_zp,2);
    z_poles_mag = abs(z_poles);
    z_poles_to_zeros_dist = zeros(N_zp);
    for ii=1:N_zp
        z_poles_to_zeros_dist(:,ii) = abs(z_poles(ii)-z_zeros(:));
    end
    % pair-up poles and zeros: start with pole nearest unit-circle and choose
    % zero closest to it; continue with increasing distance between pole and
    % unit circle.
    for ii=1:N_zp
        % select next pole closest to unit-circle
        [~,idx_next_pole] = max(z_poles_mag);
        z_poles_mag(idx_next_pole) = -Inf; % eliminate it after selection
        zp_pairs(ii,1) = idx_next_pole;
        % pair it with the closest zero
        [~,idx_next_zero] = min(z_poles_to_zeros_dist(:,idx_next_pole));
        z_poles_to_zeros_dist(idx_next_zero,:) = Inf; % eliminate if after selection
        zp_pairs(ii,2) = idx_next_zero;
    end
    % now order pairs and group into biquad structures; complex-conjugate pairs
    % should go together, and place in order of poles closest to unit-circle to
    % poles farthest from unit-circle. sort in decreasing magnitude of pole
    % already achieved in previous round, so just go down pairs
    bq_B = zeros(N_zp/2,3);
    bq_A = zeros(N_zp/2,3);
    for ii=1:N_zp/2
        bq_B(ii,:) = conv([1, -z_zeros(zp_pairs(2*ii-1,2))],[1, -z_zeros(zp_pairs(2*ii,2))]);
        bq_A(ii,:) = conv([1, -z_poles(zp_pairs(2*ii-1,1))],[1, -z_poles(zp_pairs(2*ii,1))]);
        if tf
            %hf_pair = figure();
            %zplane(bq_B(ii,:),bq_A(ii,:));
            %title(sprintf('Bi-quad %d',ii));
            %ax = axis();
            fprintf(1,'Stage-%d\n',ii);
            print_filter(bq_B(ii,:),bq_A(ii,:));
        end
    end
    % update plot of pairs
    if tf
        hf_pz_pairs = figure();
        ha_pz_pairs = axes();
        hold(ha_pz_pairs,'on');
        cmap = colormap(lines(7));
        th = linspace(0,2*pi,1e3);
        r = 1;
        for ii=1:N_zp/2
            plot(real(z_poles(zp_pairs(2*ii-1,1))),imag(z_poles(zp_pairs(2*ii-1,1))),'x','Color',cmap(ii,:),'linewidth',2,'markersize',8);
            plot(real(z_zeros(zp_pairs(2*ii-1,2))),imag(z_zeros(zp_pairs(2*ii-1,2))),'o','Color',cmap(ii,:),'linewidth',2,'markersize',8);
            plot(real(z_poles(zp_pairs(2*ii,1))),imag(z_poles(zp_pairs(2*ii,1))),'+','Color',cmap(ii,:),'linewidth',2,'markersize',8);
            plot(real(z_zeros(zp_pairs(2*ii,2))),imag(z_zeros(zp_pairs(2*ii,2))),'s','Color',cmap(ii,:),'linewidth',2,'markersize',12);
        end
        plot(ha_pz_pairs,r*cos(th),r*sin(th),'k:');
        plot(ha_pz_pairs,[0,0],ylim,'k:');
        plot(ha_pz_pairs,xlim,[0,0],'k:');
        xlabel(ha_pz_pairs,'Real Part');
        ylabel(ha_pz_pairs,'Imaginary Part');
        set(ha_pz_pairs,'box','on');
        axis(ha_pz_pairs,[-1,1,-1,1]*1.1);
    end

end