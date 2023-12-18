function LUT = eval_breaks(LUT, ecmtx)
    idx = find(~cellfun(@isempty, LUT));

    for j = 1:max(size(idx))
        % Get the Tile from the Lookup Table
        i = idx(j);
        u = LUT{i};
        
        %% Error checking
        % Ignore disassembly steps for Source and Goal tiles
        if u.name == "Source" || u.name == "Goal"
            continue;
        % Ignore target tiles that are placed around the space during
        % multistage assembly
        % Ignore deadzone tiles
        elseif u.ColorFlag == 3 || u.ColorFlag == -1
            continue
        end
        
        %% Forward channel
        % Any tile in the grid shoud have a connected forward channel input
        % at this point in the simulation
        % If it doesn't, something could be wrong
        if ~isobject(u.InputConnections{1})
            error("This Tile is in the Grid but missing a forward channel input. Something has most likely gone wrong.")
        end
            
        % Evaluate with reference to the Input Glue only
        if rand>glue_update(u.InputStrengths(1), ecmtx(i))
            % Find the Output Glue of the previous tile
            prev_tile_output_glue_name = glue_complement(u.InputGlues(1));
            prev_tile_glue_idx = find(u.InputConnections{1}.OutputGlues == prev_tile_output_glue_name);
            % Error check to avoid empty result
            if isempty(prev_tile_glue_idx)
                msg = ["Could not find ", prev_tile_glue_idx, " in the list of OutputGlues: ", u.InputConnections{1}.OutputGlues];
                error(msg)
            end
            % Disconnect, return to ON
            u.InputConnections{1}.OutputConnections{prev_tile_glue_idx} = 1; 
            % Disconnect, return to ON, but on a later step, if the tile
            % is completely disconnected, this will be switch to OFF and
            % the tile is removed from the system
            u.InputConnections{1} = 1;
        end

        %% Backward channel
        % A backward channel glue is only active after feedback
        if ~isobject(u.InputConnections{2})
            continue;
        end
        
        % Check breakage
        if rand>glue_update(u.InputStrengths(2), ecmtx(i))
            % Find the Output Glue of the previous tile
            prev_tile_output_glue_name = glue_complement(u.InputGlues(2));
            prev_tile_glue_idx = find(u.InputConnections{2}.OutputGlues == prev_tile_output_glue_name);
            % Disconnect, return to ON
            u.InputConnections{2}.OutputConnections{prev_tile_glue_idx} = 1; 
            % Disconnect, return to ON, but on a later step, if the tile
            % is completely disconnected, this will be switch to OFF and
            % the tile is removed from the system
            u.InputConnections{2} = 1;
        end
    end
end