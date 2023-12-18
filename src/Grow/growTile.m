function [LUT, ecmtx, tf] = growTile(LUT, ecmtx, n, t1, t2defn, g1, g2, G_se, dz_params)
% Checks if the LUT position is empty to avoid collisions
% Creates tile 2 from its glues definition
% Binds Tile 1 and Tile 2 together
% Adds Tile 2 into the lookup table
% ecmtx must be passed for handling deadzone tiles
    [tx, ty] = growPos(t1, g1);
    tf = false;
    if canGrow(LUT, n, tx, ty)
        % Create the object
        t2 = Tile(t2defn, G_se);
        settype(t2, "tile")
        % Set the position
        t2.Position = [tx ty];
        % Default is tile coloring
        t2.ColorFlag = 1;
        % Pass through the source tile coloring
        t2.SeedColoring = t1.SeedColoring;
        % Set the Connections arrays to each other
        bind_glues(t1, g1, t2, g2);
        % Find t2's index in the lookup table and put it there
        posidx = pos2idx(tx, ty, n);
        LUT{posidx} = t2;
        tf = true;
    elseif is_deadtile(LUT, n, tx, ty)
        dz_ecm_strength = dz_params(1);
        dz_ecm_radius = dz_params(2);
        dz_refresh_rate = dz_params(3);
        ecmtx = layer_update(ecmtx, [dz_ecm_strength, dz_ecm_radius, dz_refresh_rate], {t1}, n, 'FirstOrder');
        tf = false;
    end
end