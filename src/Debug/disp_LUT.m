function disp_LUT(LUT, myTileSet)
    disp("Printing out Lookup Table to debug")
    idx = find(~cellfun(@isempty, LUT));

    for j = 1:max(size(idx))
        % Get the Tile from the Lookup Table
        i = idx(j);
        u = LUT{i};
        
        disp(u)
        v = LUT{i}.InputConnections{1};
        if isobject(v)
            % Also print its input tile coordinates
            fprintf("Input tile position: (%d, %d)\n", v.Position(1), v.Position(2))
        end
        gn = glue_complement(u.OutputGlues(1));
        defn = myTileSet.get_weighted_filtered_random(gn);
        disp("Potentially add tile:")
        disp(defn)
    end
end