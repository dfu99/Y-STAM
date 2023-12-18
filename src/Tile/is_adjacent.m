function tf = is_adjacent(tile1, tile2)
% Checks if two tiles are adjacent (diagonally)
    x1 = tile1.Position(1); y1 = tile1.Position(2);
    x2 = tile2.Position(1); y2 = tile2.Position(2);
    
    if norm([x2-x1 y2-y1]) == sqrt(2)
        tf = 1;
    else
        tf = 0;
    end
end