function [tx, ty] = growPos(u, glue1)
% The new coordinates (output: tx, ty) of growing a new tile from the glue (input: glue1) at the
% given Tile (input: u)
    ux = u.Position(1);
    uy = u.Position(2);
    
    dx = 0;
    dy = 0;
    glue1 = char(glue1);
    compass = glue1(3);
    side = glue1(4);
    
    if compass == 'N'
        dx = 1;
    elseif compass == 'S'
        dx = -1;
    elseif compass == 'E'
        dy = 1;
    elseif compass == 'W'
        dy = -1;
    end
    
    if side == 'L'
        dy = -1;
    elseif side == 'R'
        dy = 1;
    elseif side == 'U'
        dx = 1;
    elseif side == 'D'
        dx = -1;
    end
    
    tx = ux + dx;
    ty = uy + dy;
end