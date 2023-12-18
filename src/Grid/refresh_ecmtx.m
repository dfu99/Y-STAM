function ecmtx = refresh_ecmtx(LUT, lastLUT, ecmtx, ecm_params, decay_params)

    ecm_strength = ecm_params{1};
    ecm_signal_radius = ecm_params{2};
    mtx_refresh_rate = ecm_params{3};

    mtx_decay_rate = decay_params(1);
    mtx_decay_rate_on = decay_params(2);

    n = sqrt(length(LUT));
    grid = LUT2grid(lastLUT);
    % Calculate the decay for occupied and non-occupied positions
    ecmtx = (grid>0) .* ecmtx * 1/2^(mtx_decay_rate*mtx_decay_rate_on) + (grid==0) .* ecmtx * 1/2^mtx_decay_rate;
    % Translate lookup table LUT to temporary grid
    bgrid = zeros(n);
    for i=1:n*n
        if isempty(LUT{i})
            bgrid(i) = 0;
        elseif LUT{i}.ColorFlag == -1
            bgrid(i) = -1;
        else
            bgrid(i) = 1; 
        end
    end
    % Before the grid update happens, this records the last changed
    % positions
    dgrid = bgrid - grid;
    dgrid = dgrid > 0;
    j = find(dgrid);
    % Skip the update here if in repulsive mode
    if ecm_strength > 0
        if ecm_signal_radius == 0
            arg = 'FlatSum';
        else
            arg = 'FirstOrderSum';
        end
        ecmtx = layer_update(ecmtx, [ecm_strength, ecm_signal_radius, mtx_refresh_rate], {LUT{j}}, n, arg, 'Grid', grid);
    end
end