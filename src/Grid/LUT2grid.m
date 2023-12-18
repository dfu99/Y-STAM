function grid = LUT2grid(LUT)
% Translate Lookup Table to Grid

    n = sqrt(length(LUT));
    grid = zeros(n);
    for i=1:n^2
        if isempty(LUT{i})
            grid(i) = 0;
        elseif LUT{i}.SeedColoring ~= 0
            grid(i) = 4 + LUT{i}.SeedColoring;
        else
            grid(i) = LUT{i}.ColorFlag;
        end
    end
end