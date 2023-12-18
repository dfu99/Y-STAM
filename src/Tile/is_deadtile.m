function tf = is_deadtile(LUT, n, x, y)
% Checks if the tile at the LUT index is a deadzone tile

    idx = pos2idx(x, y, n);
    range = (1<=x) && (x<=n) && (1<=y) && (y<=n);
    if range
        t = LUT{idx};
    else
        tf = false;
        return;
    end
    if range && t.name == "Dead"
        tf = true;
        return;
    else
        tf = false;
        return;
    end
end