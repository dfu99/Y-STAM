function bind_glues(tile1, glue1, tile2, glue2)
% Connect Tile1 and Tile2 together via glue1 and glue2

    % Error checking
    % We must confirm that the two glues given as parameters can actually
    % bind
    if ~binding_rules(glue1, glue2)
        msg = strcat(glue1, " and ", glue2, " are non-complementary.");
        error(msg)
    end
    
    % Make sure we have the right element number
    outputidx = 0;
    inputidx = 0;
    for idx = 1:size(tile1.OutputGlues, 2)
        if tile1.OutputGlues(idx) == glue1
            outputidx = idx;
        end
    end
    for idx = 1:size(tile2.InputGlues, 2)
        if tile2.InputGlues(idx) == glue2
            inputidx = idx;
        end
    end
    
    % Post error checking
    % If the glues were not found in the provided tiles
    if outputidx == 0 || inputidx == 0
        error("The Glues were not found on the tiles. Were they initialized correctly?")
    end
    
    % Finally, set the attachment between the two tiles
    tile1.OutputConnections{outputidx} = tile2;
    tile2.InputConnections{inputidx} = tile1;
end