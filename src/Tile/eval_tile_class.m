function tile_class = eval_tile_class(mytile)
% Evaluates the Tile Class as either a branching tile or standard tile
% Branching tiles have one Input and multiple Outputs
% Standard tiles have one Input and one Output

    output_count = 0;
    for i = 1:length(mytile.OutputGlues)
        this_glue = char(mytile.OutputGlues(i));
        if this_glue(1:2) == 'FO'
            output_count = output_count + 1;
        end
    end
    
    if output_count > 1
        tile_class = "branching";
    else
        tile_class = "standard";
    end
end