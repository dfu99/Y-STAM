function tile_type = eval_tile_defn(defn)
% Evaluates the Tile Class as either a branching tile or standard tile
% Branching tiles have one Input and multiple Outputs
% Standard tiles have one Input and one Output

    output_count = 0;
    for i = defn
        this_glue = char(i);
        if this_glue(1:2) == 'FO'
            output_count = output_count + 1;
        end
    end
    
    if output_count > 1
        tile_type = "branching";
    else
        tile_type = "standard";
    end
end