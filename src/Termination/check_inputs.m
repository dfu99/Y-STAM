function [NW, NWidx, NE, NEidx, SE, SEidx, SW, SWidx] = check_inputs(goal_tile, LUT, n)
% Check for left side inputs to any tile
% u

    % Calculate positions of adjacent tile positions
    goal_posx = goal_tile.Position(1); goal_posy = goal_tile.Position(2);

    % There are only 4 adjacent positions
    % NW, NE, SE, SW
    Sx = goal_posx-1; Wy = goal_posy-1;
    Nx = goal_posx+1; Ey = goal_posy+1;

    NW=true; NE=true; SE=true; SW=true;
    NWidx=-1;NEidx=-1;SEidx=-1;SWidx=-1;
    % Check if tiles exist at those positions
    if Sx < 1 % Catch edge case
        SW = false;
        SE = false;
    elseif Ey > n
        SE = false;
        NE = false;
    elseif Wy < 1
        NW = false;
        SW = false;
    elseif Nx > n
        NW = false;
        NE = false;
    end
    
    if SW
        SWidx = pos2idx(Sx, Wy, n);
        if isobject(LUT{SWidx})
            if ismember("FOEU", LUT{SWidx}.OutputGlues) || ismember("FONR", LUT{SWidx}.OutputGlues)
                SW = true;
            else
                SW = false;
            end
        else
            SW = false;
        end
    end

    if SE
        SEidx = pos2idx(Sx, Ey, n);
        if isobject(LUT{SEidx})
            if ismember("FOWU", LUT{SEidx}.OutputGlues) || ismember("FONL", LUT{SEidx}.OutputGlues)
                SE = true;
            else
                SE = false;
            end
        else
            SE = false;
        end
    end
    
    if NW
        NWidx = pos2idx(Nx, Wy, n);
        if isobject(LUT{NWidx})
            if ismember("FOED", LUT{NWidx}.OutputGlues) || ismember("FOSR", LUT{NWidx}.OutputGlues)
                NW = true;
            else
                NW = false;
            end
        else
            NW = false;
        end
    end

    if NE
        NEidx = pos2idx(Nx, Ey, n);
        if isobject(LUT{NEidx})
            if ismember("FOWD", LUT{NEidx}.OutputGlues) || ismember("FOSL", LUT{NEidx}.OutputGlues)
                NE = true;
            else
                NE = false;
            end
        else
            NE = false;
        end
    end
end
