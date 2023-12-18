function FreeEdges = refresh_free_edges(LUT, FreeEdges)
    % Check each tile position in lookup table
    % Add to list of possible binding sites
    idx = find(~cellfun(@isempty, LUT));
    for i = idx
        u = LUT{i};
        % check for active glues
        for j = 1:length(u.OutputConnections)
            OCElement = u.OutputConnections{j};
            % isobject must be first to avoid comparator typing problems
            if ~isobject(OCElement) && OCElement == 1
                FreeEdges{end+1} = u;
            end
        end
    end
end