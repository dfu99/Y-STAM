function valid = canGrow(LUT, n, x, y)
% Check if we can grow into the position x,y by checking the lookup table
% index
    idx = pos2idx(x, y, n);
    range = (1<=x) && (x<=n) && (1<=y) && (y<=n);
    try
        if range && isempty(LUT{idx})
            valid = true;
        else
            valid = false;
        end
    catch ME
        disp("canGrow idx:")
        disp(idx)
        fprintf("x: %d, y: %d, n: %d\n", x, y, n)
        rethrow(ME)
    end
end