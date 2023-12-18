function [glue1, glue2] = probe_glues(tile1, tile2)
% Probes the glues on tile1 and tile2 to check which glues can connect the
% two tiles
% Tile1 goes to Source
% Tile2 goes to Goal

    % Error flagging
    % Cannot connect if they are not adjacent
    if ~is_adjacent(tile1, tile2)
        error("Cannot connect non-adjacent tiles.")
    end

    % Get their relative directions
    x1 = tile1.Position(1); y1 = tile1.Position(2);
    x2 = tile2.Position(1); y2 = tile2.Position(2);

    % First assume tile1 is toSource and tile2 is toGoal
    % Glue direction
    x = x2 - x1;
    y = y2 - y1;

    % N, U is x+1
    % S, D is x-1
    % E, R is y+1
    % W, L is y-1

    % Look for FO- NR or EU
    if all([x y] == [1 1])
        if ismember("FONR", tile1.OutputGlues)
            glue1 = "FONR";
        elseif ismember("FOEU", tile1.OutputGlues)
            glue1 = "FOEU";
        end
    
    % Look for FO- NL or WU
    elseif all([x y] == [1 -1])
        if ismember("FONL", tile1.OutputGlues)
            glue1 = "FONL";
        elseif ismember("FOWU", tile1.OutputGlues)
            glue1 = "FOWU";
        end

    % SR or ED
    elseif all([x y] == [-1 1])
        if ismember("FOSR", tile1.OutputGlues)
            glue1 = "FOSR";
        elseif ismember("FOED", tile1.OutputGlues)
            glue1 = "FOED";
        end

    % SL or WD
    elseif all([x y] == [-1 -1])
        if ismember("FOSL", tile1.OutputGlues)
            glue1 = "FOSL";
        elseif ismember("FOWD", tile1.OutputGlues)
            glue1 = "FOWD";
        end
    end
    
    % Generate glue2 as the complement of glue1
    try
        glue2 = glue_complement(glue1);
    catch
        msg = "Exception: Could not assign a glue for the case ["+num2str(x)+" "+num2str(y)+"].";
        error(msg)
    end
    if ~ismember(glue2, tile2.InputGlues)
        error("Tile2 cannot reciprocate the Tile1 connection.")
    end
end