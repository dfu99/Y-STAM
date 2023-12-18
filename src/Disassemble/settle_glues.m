function LUT = settle_glues(LUT)    
    % If both glues are in the ON state, but one is attached and one isn't
    % give the detached glue a chance to reattach
    idx = find(~cellfun(@isempty, LUT));
    for j = 1:max(size(idx))
        i = idx(j);
        u = LUT{i};
        if ~isobject(u)
            continue
        end
        % Ignore disassembly steps for Source and Goal tiles
        if u.name == "Source" || u.name == "Goal"
            continue;
        end
        % If one glue is attached but the other is detached and active
        % (1 - active, 0 - latent, -1 - off), evaluate a chance of reattachment
        if isobject(u.InputConnections{1}) && ~isobject(u.InputConnections{2}) && u.InputConnections{2} == 1
            % Find the Output Glue of the previous tile
            prev_tile = u.InputConnections{1};
            prev_tile_output_glue_name = glue_complement(u.InputGlues(1));
            prev_tile_output_glue_name(1) = 'B';
            prev_tile_glue_idx = find(prev_tile.OutputGlues == prev_tile_output_glue_name);
            
            % Re-add connections
            prev_tile.OutputConnections{prev_tile_glue_idx} = u;
            u.InputConnections{2} = prev_tile;

        elseif isobject(u.InputConnections{2}) && ~isobject(u.InputConnections{1}) && u.InputConnections{1} == 1
            % Find the Output Glue of the previous tile
            prev_tile = u.InputConnections{2};
            prev_tile_output_glue_name = glue_complement(u.InputGlues(2));
            prev_tile_output_glue_name(1) = 'F';
            prev_tile_glue_idx = find(prev_tile.OutputGlues == prev_tile_output_glue_name);
            
            % Re-add connections
            prev_tile.OutputConnections{prev_tile_glue_idx} = u;
            u.InputConnections{1} = prev_tile;
        end
    end
end