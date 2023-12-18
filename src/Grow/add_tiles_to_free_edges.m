function [LUT, ecmtx] = add_tiles_to_free_edges(LUT, ecmtx, n, FreeEdges, myTileSet, growth_params, dz_params)
    usetileconc = growth_params(1);
    G_se = growth_params(2);

    % For each free binding site, add a tile
    % If forward rate rf = 1, add tiles to all active glues
    % If forward rate rf < 1, add models by rate probability
    for i=1:max(size(FreeEdges))
        u = FreeEdges{i};
        % Check if it is a branching tile
        % A branching tile has multiple Forward Output glues
        tile_class = eval_tile_class(u);
        if tile_class == "branching"
            % Attach a tile at all glues
            for j = u.OutputGlues
                glue1 = char(j);
                if strcmp(glue1(1:2), 'FO')
                    glue1 = j;
                    glue2 = glue_complement(glue1);
                    new_tile_defn = myTileSet.get_weighted_filtered_random(glue2);
                    % Check that a valid tile was returned
                    if ~is_nulltile(new_tile_defn)
                        [LUT, ecmtx, tf] = growTile(LUT, ecmtx, n, u, new_tile_defn, glue1, glue2, G_se, dz_params);
                    else
                        tf = false;
                    end
                    if tf && usetileconc
                        myTileSet.dec_conc(new_tile_defn)
                    end
                end
            end
        % Otherwise it is a standard tile with only one output
        % Standard tiles should only ever have at most 1 Forward Output glue
        else
            % If the first output is active (implies the other is inactive)
            if ~isobject(u.OutputConnections{1}) && u.OutputConnections{1} == 1
                glue1 = u.OutputGlues(1);
                glue2 = glue_complement(glue1);
                new_tile_defn = myTileSet.get_weighted_filtered_random(glue2);
                % Check that a valid tile was returned
                if ~is_nulltile(new_tile_defn)
                    [LUT, ecmtx, tf] = growTile(LUT, ecmtx, n, u, new_tile_defn, glue1, glue2, G_se, dz_params);
                else
                    tf = false;
                end
                if tf && usetileconc
                    myTileSet.dec_conc(new_tile_defn)
                end
            % If the first output is filled and the second output is active
            % (This case should not occur if tiles are all set up correctly)
            elseif ~isobject(u.OutputConnections{2}) && u.OutputConnections{2} == 1 && u.OutputGlues(2) ~= "NULL"
                error("ERROR: add_tiles_to_free_edges case 2 occurred.")
            end
        end
    end
    return;
end