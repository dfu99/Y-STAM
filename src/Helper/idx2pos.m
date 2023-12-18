function [x, y] = idx2pos(idx, n)
    x = ceil(idx/n);
    y = mod(idx, n);
    if y == 0
        y = n;
    end
end