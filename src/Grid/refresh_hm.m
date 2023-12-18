function heatmap = refresh_hm(LUT, heatmap, n)
% Translate Lookup Table to Grid
    for i=1:n*n
        % Record the time since a tile was last seen
        % 0 means a tile currently exists at this position
        if isempty(LUT{i})
            heatmap(i) = heatmap(i) + 1;
        else
            heatmap(i) = 0;
        end
    end
    
end