function tf = is_nulltile(defn)
% Determines if tile is a null tile
% Null tiles are usually used as a placeholder to indicate that nothing
% happened

    if all(defn == "NULL")
        tf = 1;
        return;
    else
        tf = 0;
        return;
    end
end
