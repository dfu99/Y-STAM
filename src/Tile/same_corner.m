function tf = same_corner(GlueName1, GlueName2)
% Verifies if the two parameter glues are in the same corner
% The corners are:
% SR-ED
% NR-EU
% NL-WU
% SL-WD
    g1 = char(GlueName1);
    g2 = char(GlueName2);
    if g1(3:4) == "SR" && g2(3:4) == "ED"
        tf = true;
        return;
    elseif g1(3:4) == "NR" && g2(3:4) == "EU"
        tf = true;
        return;
    elseif g1(3:4) == "NL" && g2(3:4) == "WU"
        tf = true;
        return;
    elseif g1(3:4) == "SL" && g2(3:4) == "WD"
        tf = true;
        return;
    elseif g1(3:4) == "ED" && g2(3:4) == "SR"
        tf = true;
        return;
    elseif g1(3:4) == "EU" && g2(3:4) == "NR"
        tf = true;
        return;
    elseif g1(3:4) == "WU" && g2(3:4) == "NL"
        tf = true;
        return;
    elseif g1(3:4) == "WD" && g2(3:4) == "SL"
        tf = true;
        return;
    else
        tf = false;
        return;
    end
end