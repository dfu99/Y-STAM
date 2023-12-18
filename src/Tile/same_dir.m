function tf = same_dir(GlueName1, GlueName2)
% Verifies if the two parameter glues are in the same glue location
    g1 = char(GlueName1);
    g2 = char(GlueName2);
    if g1(3:4) == g2(3:4)
        tf = true;
        return;
    else
        tf = false;
        return;
    end
end