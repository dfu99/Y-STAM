function tf = same_side(GlueName1, GlueName2)
% Verifies if the two parameter glues are in the same edge side of the tile
    g1 = char(GlueName1);
    g2 = char(GlueName2);
    if g1(3) == g2(3)
        tf = true;
        return;
    else
        tf = false;
        return;
    end
end