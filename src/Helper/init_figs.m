function fig_handles = init_figs(X, Y, W, H, padding)
% Initialize figure handles
% Default size for small figures (support matrix and heat map) is 560 420
% Default size for large figures (grid) is 1120 840
% Position is anchor of bottom left of window [X Y W H]
    if nargin == 0
        X = 0;
        Y = 0;
        W = 1120;
        H = 840;
        padding = 80;
    end
    if ~exist('padding', 'var')
        padding = 80;
    end
    
    fig_gr = figure("Position", [X Y W H]); % grid figure
    title("Path")
    fig_hm = figure("Position", [X+W+padding Y+0 W/2 H/2]); % heat map figure
    title("Heat map")
    fig_ecm = figure("Position", [X+W+padding Y+H/2+padding W/2 H/2]); % support matrix figure
    title("Spatial Memory")
    fig_handles = {fig_gr, fig_hm, fig_ecm};

end
