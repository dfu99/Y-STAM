function ecmtx = layer_update(ecmtx, ecmvars, tarr, n, profile, varargin)
% Layer update rules for memory layer (ecmtx = [e]xtra[c]ellular [m]a[t]ri[x])
% ecmvars strength, radius, mdr, mdron
% tarr array of tiles
% n size of grid
% This function adds ecmtx, decaying first order by distance, around the
% location specific by the tile

    fcnp = inputParser;
    addRequired(fcnp, 'ecmtx')
    addRequired(fcnp, 'ecmvars')
    addRequired(fcnp, 'tarr')
    addRequired(fcnp, 'n')
    addRequired(fcnp, 'profile')
    addParameter(fcnp, 'Exclusion', false)
    addParameter(fcnp, 'Grid', [])
    parse(fcnp, ecmtx, ecmvars, tarr, n, profile, varargin{:});
    ecmtx = fcnp.Results.ecmtx;
    ecmvars = fcnp.Results.ecmvars;
    tarr = fcnp.Results.tarr;
    n = fcnp.Results.n;
    profile = fcnp.Results.profile;
    
    signal_strength = ecmvars(1);
    signal_radius = ecmvars(2);
    % Refresh rate optional
    if max(size(ecmvars)) == 3
        mrr = ecmvars(3);
    elseif profile == "LinearLag"
        error("Using LinearLag mode but missing decay rates arguments.")
    end

    if max(size(tarr)) == 2 && isnumeric(tarr)
        iter = 1;
    else
        iter = max(size(tarr));
    end
    for i = 1:iter
        % Check if the inputs are Tile Objects
        if iscell(tarr) && isobject(tarr{i})
            t = tarr{i};
            % Get the square outline of the grid within the radius
            trow = t.Position(1); tcol = t.Position(2);
        % Otherwise, the input is should be an array of numeric positions
        else
            t = tarr;
            trow = t(1); tcol = t(2);
        end
        % Define as bottom left to upper right corner
        crow_bl = floor(trow-signal_radius);
        ccol_bl = floor(tcol-signal_radius);
        crow_ur = ceil(trow+signal_radius);
        ccol_ur = ceil(tcol+signal_radius);
        % row from bottom to top
        for r = crow_bl:crow_ur
            if ~(r > n || r < 1)
                % columns from left to right
                for c = ccol_bl:ccol_ur
                    if ~(c > n || c < 1)
                        % Calculate distance to tile
                        d = sqrt((r-trow)^2+(c-tcol)^2);
                        % Sets signal to signal maximum with first order
                        % distribution on distance
                        if profile == "FirstOrder"
                            signal = signal_strength * exp(-d/signal_radius);
                        % Adds signal up to signal maximum at first order
                        % distribution on distance, at a rate mdr
                        elseif profile == "FirstOrderSum"
                            signal = ecmtx(r, c) + (signal_strength - ecmtx(r, c)) * exp(-d/signal_radius) * mrr;
                        elseif profile == "UnboundFirstOrderSum"
                            signal = ecmtx(r, c) + signal_strength * exp(-d/signal_radius);
                        elseif profile == "Linear"
                            signal = signal_strength * abs(signal_radius - d)/signal_radius;
                        elseif profile == "LinearSum"
                            signal = ecmtx(r, c) + (signal_strength - ecmtx(r, c)) * abs(signal_radius-d)/signal_radius * mrr;
                        elseif profile == "Flat"
                            signal = signal_strength;
                        elseif profile == "FlatSum"
                            signal = ecmtx(r, c) + (signal_strength - ecmtx(r, c)) * mrr;
                        else % Flat by fdefault
                            signal = signal_strength;
                        end
                        if signal > ecmtx(r, c)
                            ecmtx(r, c) = signal;
                        elseif signal < 0
                            ecmtx(r, c) = signal;
                        end
                    end
                end
            end
        end
    end
end